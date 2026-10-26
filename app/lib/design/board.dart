import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The four reference screens of the design boards. Each has its own board with exact positions in
/// logical points, so the child screens are laid out in those coordinates and scaled to the window.
enum BoardClass {
  /// iPhone 16 landscape, boards 10 and 13.
  phone(Size(852, 393)),

  /// The smallest supported phone, board 12.
  phoneSE(Size(667, 375)),

  /// iPad landscape, boards 22 and 23.
  tabletLandscape(Size(1180, 820)),

  /// iPad portrait, boards 25 and 26.
  tabletPortrait(Size(820, 1180));

  const BoardClass(this.size);

  final Size size;

  bool get isTablet => this == tabletLandscape || this == tabletPortrait;
}

/// Which board a window is laid out like. Follows the window, not the device (split screen,
/// foldables): from 600 on the short side it is a tablet.
BoardClass boardClassFor(Size window) {
  if (math.min(window.width, window.height) >= 600) {
    return window.height > window.width ? BoardClass.tabletPortrait : BoardClass.tabletLandscape;
  }
  return window.longestSide <= 700 ? BoardClass.phoneSE : BoardClass.phone;
}

/// A drawing area in board coordinates. The children are placed with `Positioned` using the numbers
/// of the board's own CSS, and the whole drawing is scaled to fit the window (keeping its shape);
/// whatever is left over is filled with [background].
class BoardCanvas extends StatelessWidget {
  const BoardCanvas({super.key, required this.background, required this.board, required this.children});

  final Color background;
  final BoardClass board;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: background,
    child: SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: board.size.width,
          height: board.size.height,
          child: ClipRect(child: Stack(children: children)),
        ),
      ),
    ),
  );
}

/// An SVG from the board artwork, drawn at the size the board gives it.
class BoardSvg extends StatelessWidget {
  const BoardSvg(this.asset, {super.key, this.width, this.height, this.label, this.fit = BoxFit.contain});

  final String asset;
  final double? width;
  final double? height;

  /// Read by screen readers; null for pure decoration.
  final String? label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: width,
    height: height,
    fit: fit,
    excludeFromSemantics: label == null,
    semanticsLabel: label,
  );
}
