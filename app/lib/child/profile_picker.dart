import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';

/// "Who is playing now?" (board 11, right half). Siblings share the device, so every child has a
/// card. The "+" circle leads to the parent gate: children cannot add or remove profiles. The sea,
/// the cards (112 by 136, radius 28), the bubble and the dashed "+" are the board's own measurements,
/// scaled up on tablets.
class ProfilePicker extends StatelessWidget {
  const ProfilePicker({super.key, required this.profiles, required this.onChoose, required this.onAdd});

  final List<Profile> profiles;
  final void Function(Profile) onChoose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    // Board 11 is a phone board; the other classes use the same composition at a different scale.
    final double k = switch (board) {
      BoardClass.phone => 1,
      BoardClass.phoneSE => 0.92,
      BoardClass.tabletLandscape => 1.4,
      BoardClass.tabletPortrait => 1.3,
    };
    final Size size = board.size;
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.worldSea1,
        board: board,
        children: <Widget>[
          Positioned.fill(
            child: BoardSvg(
              'assets/art/scenes/picker.svg',
              width: size.width,
              height: size.height,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BoardBubble(
                    text: He.pickerTitle.text,
                    fontSize: 22 * k,
                    padding: EdgeInsets.symmetric(horizontal: 16 * k, vertical: 8 * k),
                  ),
                  SizedBox(height: 12 * k),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 24 * k,
                    runSpacing: 16 * k,
                    children: <Widget>[
                      for (int i = 0; i < profiles.length; i++)
                        _ProfileCard(
                          profile: profiles[i],
                          k: k,
                          lifted: i == 0,
                          onTap: () => onChoose(profiles[i]),
                        ),
                      _AddCircle(k: k, onTap: onAdd),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.k, required this.lifted, required this.onTap});

  final Profile profile;
  final double k;

  /// Board 11 shows the first card lifted 8 px, as if it were being pressed.
  final bool lifted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: profile.name,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.translate(
        offset: Offset(0, lifted ? -8 * k : 0),
        child: Container(
          // The board's 112 by 136 is the least size: the card grows taller with the system text (QA-19).
          constraints: BoxConstraints(minWidth: 112 * k, maxWidth: 112 * k, minHeight: 136 * k),
          padding: EdgeInsets.only(top: 8 * k),
          decoration: BoxDecoration(
            color: TokenColors.paper,
            borderRadius: BorderRadius.circular(TokenRadius.xl * k),
            boxShadow: <BoxShadow>[
              BoxShadow(color: TokenColors.cardLip, offset: Offset(0, 6 * k)),
              BoxShadow(
                color: const Color.fromRGBO(43, 35, 80, 0.14),
                blurRadius: 16 * k,
                offset: Offset(0, 6 * k),
              ),
            ],
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AvatarPicture(avatarId: profile.avatar, size: 84 * k),
                SizedBox(height: 2 * k),
                Text(
                  profile.name,
                  style: AppText.fixed(size: 20 * k, weight: 700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AddCircle extends StatelessWidget {
  const _AddCircle({required this.k, required this.onTap});

  final double k;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64 * k,
    height: 64 * k,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Nitzi sits under the circle, as on board 11.
        Positioned(
          left: -4 * k,
          top: 40 * k,
          child: BoardSvg('assets/art/ui/nitzi_sit.svg', width: 100 * k, height: 118 * k),
        ),
        Semantics(
          button: true,
          label: He.pickerAddSemantics.text,
          child: GestureDetector(
            key: const Key('picker-add'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: CustomPaint(
              painter: _DashedCirclePainter(color: TokenColors.inkSoft, width: 2),
              child: Container(
                width: 64 * k,
                height: 64 * k,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(255, 255, 255, 0.7),
                ),
                child: ExcludeSemantics(
                  child: BoardSvg('assets/art/ui/plus.svg', width: 28 * k, height: 28 * k),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A dashed ring, as in the board's `border: 2px dashed`.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final Path ring = Path()
      ..addOval(Rect.fromLTWH(width / 2, width / 2, size.width - width, size.height - width));
    for (final metric in ring.computeMetrics()) {
      double at = 0;
      while (at < metric.length) {
        canvas.drawPath(metric.extractPath(at, at + 6), paint);
        at += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color || old.width != width;
}
