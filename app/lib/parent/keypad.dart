import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// A number pad for the gate and the PIN. [order] is the digit order shown, so the gate can shuffle
/// it. Digits are drawn left to right: they are numerals. Adult UI, so the buttons are plain.
class ParentKeypad extends StatelessWidget {
  const ParentKeypad({
    super.key,
    required this.order,
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
  });

  final List<int> order;
  final void Function(int digit) onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  static const List<int> plain = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 0];

  @override
  Widget build(BuildContext context) {
    // Nine digits in a 3-by-3 block; the tenth and the delete key share the last row.
    final List<int> d = order.length == 10 ? order : plain;
    final List<List<int>> rows = <List<int>>[d.sublist(0, 3), d.sublist(3, 6), d.sublist(6, 9)];
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: MathIsolate(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final List<int> row in rows)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[for (final int n in row) _Key(label: '$n', onTap: () => onDigit(n))],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(width: _Key.size + 8),
                  _Key(label: '${d[9]}', onTap: () => onDigit(d[9])),
                  _Key(
                    label: '',
                    icon: Icons.backspace_outlined,
                    semantics: He.pinDelete.text,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.icon, this.semantics});

  static const double size = 64;

  final String label;
  final IconData? icon;
  final String? semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Semantics(
      button: true,
      label: semantics ?? label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.paper,
            borderRadius: BorderRadius.circular(TokenRadius.md),
            border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
          ),
          child: ExcludeSemantics(
            child: icon != null
                ? Icon(icon, color: TokenColors.night)
                : Text(label, style: AppText.parent(TokenType.parentStat, color: TokenColors.night)),
          ),
        ),
      ),
    ),
  );
}

/// Dots that show how many digits have been typed, without showing the digits.
class EntryDots extends StatelessWidget {
  const EntryDots({super.key, required this.filled, this.slots = 6});

  final int filled;
  final int slots;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (int i = 0; i < slots; i++)
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled ? TokenColors.night : Colors.transparent,
            border: Border.all(color: TokenColors.night, width: TokenBorder.thin),
          ),
        ),
    ],
  );
}
