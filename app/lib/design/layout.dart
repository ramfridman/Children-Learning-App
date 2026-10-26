import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'board.dart';
import 'token_types.dart';
import 'tokens.g.dart';

/// The window size class (design spec 7): it follows the window, not the device, so split-screen
/// and foldables work. Widths from 600 up on the short side use the tablet layout.
enum SizeClass { phone, phoneSE, tablet }

SizeClass sizeClassFor(Size size) {
  if (math.min(size.width, size.height) >= 600) return SizeClass.tablet;
  return size.longestSide <= 700 ? SizeClass.phoneSE : SizeClass.phone;
}

/// What a screen needs to know about the space it has. Built from the window by [LayoutScope].
class AppLayout {
  const AppLayout({required this.size, required this.band});

  final Size size;
  final Band band;

  SizeClass get sizeClass => sizeClassFor(size);

  /// Which design board the window is laid out like (boards 10, 12, 22 and 25).
  BoardClass get board => boardClassFor(size);

  bool get isTablet => sizeClass == SizeClass.tablet;
  bool get isTabletPortrait => isTablet && size.height > size.width;

  LayoutClass get tokens => switch (sizeClass) {
    SizeClass.phone => TokenLayout.classPhone,
    SizeClass.phoneSE => TokenLayout.classPhoneSE,
    SizeClass.tablet => TokenLayout.classTablet,
  };

  BandTouch get touch => TokenTouch.band[band]!;

  double get answerSize => isTablet ? touch.answerTablet : touch.answerPhone;
  double get answerGap => isTablet ? touch.gapTablet : touch.gapPhone;
  double get pebbleSize => TokenComponent.pebbleSize[band]!;

  static AppLayout of(BuildContext context) {
    final _LayoutInherited? scope = context.dependOnInheritedWidgetOfExactType<_LayoutInherited>();
    assert(scope != null, 'AppLayout.of needs a LayoutScope above it');
    return scope!.layout;
  }
}

/// Provides [AppLayout] to the screens below it.
class LayoutScope extends StatelessWidget {
  const LayoutScope({super.key, required this.band, required this.child});

  final Band band;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return _LayoutInherited(
      layout: AppLayout(size: size, band: band),
      child: child,
    );
  }
}

class _LayoutInherited extends InheritedWidget {
  const _LayoutInherited({required this.layout, required super.child});

  final AppLayout layout;

  @override
  bool updateShouldNotify(_LayoutInherited old) =>
      old.layout.size != layout.size || old.layout.band != layout.band;
}

/// Maths is always read left to right, even inside a right-to-left screen: number lines start at 0
/// on the left, equations and clocks are never mirrored (design spec 8). Wrap every such tile in this.
class MathIsolate extends StatelessWidget {
  const MathIsolate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}
