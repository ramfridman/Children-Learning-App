import 'package:flutter/widgets.dart';

/// The sign a division is drawn with. ÷ is the default (CLAUDE.md, Hebrew rules); a parent can choose the colon in the parent area, and
/// the choice is kept on this device with the other settings of the app.
enum DivisionSign {
  /// ÷
  obelus,

  /// :
  colon;

  /// The setting as it is stored.
  String get stored => name;

  static DivisionSign fromStored(String? value) =>
      value == colon.name ? DivisionSign.colon : DivisionSign.obelus;
}

/// The division sign the screens below draw with. A screen that has none above it draws ÷.
class MathSigns extends InheritedWidget {
  const MathSigns({super.key, required this.division, required super.child});

  final DivisionSign division;

  static DivisionSign of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MathSigns>()?.division ?? DivisionSign.obelus;

  @override
  bool updateShouldNotify(MathSigns old) => old.division != division;
}

/// What an `op:` token of a number sentence is drawn as, for the sign [sign] after the colon of the token (`op:x` gives `x`): the minus
/// sign for `-`, × for `x`, and for `:` the child's division sign. Any other sign (`+`, `=`, `<`, `>`, brackets) is drawn as it is.
String signGlyph(String sign, DivisionSign division) => switch (sign) {
  '-' => '−',
  'x' => '×',
  ':' => division == DivisionSign.obelus ? '÷' : ':',
  _ => sign,
};
