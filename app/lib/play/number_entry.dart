import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

// The keypad of a number answer (`tap_answer` 1.4, M10 X3): a calm row of digit keys, a delete key and a check key, in the place of the
// answer tiles. The number is read and typed left to right, whatever the language, and is shown where the question has its gap. There
// is no time on it and nothing counts what the child presses until the check; a wrong number is "not yet" like a wrong tile.

/// The keys, in the order they stand: two rows of six, each read from the left.
const List<String> keypadKeys = <String>['1', '2', '3', '4', '5', 'back', '6', '7', '8', '9', '0', 'done'];

/// The most digits a number can take (the schema's numbers go to 10,000).
const int mostDigits = 5;

/// Where the keys of the keypad stand on a board: a key [key] points wide, a tap margin of [slop] round it, [columns] to a row.
class KeypadLayout {
  const KeypadLayout._(this.spec, this.key, this.slop);

  /// The keypad of [spec]'s board: 56 points a key on a phone (the least a child's control may be in Bands B and C), 64 on a tablet.
  factory KeypadLayout.of(ActivitySpec spec) => KeypadLayout._(spec, spec.stageIsCard ? 64 : 56, 4);

  final ActivitySpec spec;
  final double key;
  final double slop;

  static const int columns = 6;

  /// How far the pad's first row stands below the top of the tiles' box: the box starts 12 over the tiles (an answer tile's tap margin)
  /// and a key has 4 of its own.
  static const double lift = 8;

  double get pitch => key + 2 * slop;
  double get width => columns * pitch;
  double get height => 2 * pitch;

  /// The left edge of the pad, in board points: the answer tiles' box, centred.
  double get left => spec.tilesLeft + (spec.tilesWidth - width) / 2;

  /// The top of the first row's keys (where an answer tile's top is).
  double get top => spec.tilesTop;

  /// The drawn square of key [i] (its place in [keypadKeys]), in board points.
  Rect rect(int i) =>
      Rect.fromLTWH(left + (i % columns) * pitch + slop, top + (i ~/ columns) * pitch, key, key);

  /// The point on the top edge of key [name] where a hint's fingertip ends.
  Offset tip(String name) => rect(keypadKeys.indexOf(name)).topCenter;

  /// The right edge of the keys, in board points.
  double get right => left + width - slop;
}

/// The pad. [lit] are the keys that glow (the digits the answer needs, when the answer is being shown); [enabled] is false while the last
/// number is being answered.
class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.layout,
    required this.onKey,
    this.lit = const <String>{},
    this.canCheck = false,
    this.enabled = true,
  });

  final KeypadLayout layout;
  final void Function(String key) onKey;
  final Set<String> lit;

  /// There is a number to check (a key for the check stands out only then).
  final bool canCheck;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      key: const Key('keypad'),
      width: layout.width,
      height: layout.height + KeypadLayout.lift,
      child: Stack(
        children: <Widget>[
          for (final (int i, String k) in keypadKeys.indexed)
            Positioned(
              left: (i % KeypadLayout.columns) * layout.pitch,
              top: (i ~/ KeypadLayout.columns) * layout.pitch + KeypadLayout.lift,
              child: _key(context, k),
            ),
        ],
      ),
    ),
  );

  Widget _key(BuildContext context, String k) {
    final bool done = k == 'done';
    final Widget face = switch (k) {
      'back' => const Icon(Icons.backspace_outlined, size: 26, color: TokenColors.ink),
      'done' => Icon(
        Icons.check_rounded,
        size: 32,
        color: canCheck ? TokenColors.ink : TokenColors.inkSoft.withValues(alpha: 0.5),
      ),
      _ => Text(k, style: AppText.fixed(size: layout.key * 0.55, weight: 800, lineHeight: 1)),
    };
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: AnswerTile(
        key: Key('key-$k'),
        semanticLabel: switch (k) {
          'back' => He.keypadDeleteSemantics.text,
          'done' => He.keypadDoneSemantics.text,
          _ => k,
        },
        size: layout.key,
        width: layout.key,
        slop: layout.slop,
        state: lit.contains(k) ? AnswerState.selected : AnswerState.idle,
        onPressed: enabled ? () => onKey(k) : null,
        child: done && canCheck
            ? DecoratedBox(
                decoration: const BoxDecoration(color: TokenColors.sparkTint),
                child: Center(child: face),
              )
            : Center(child: face),
      ),
    );
  }
}

/// What the child has typed, drawn where the question has its gap (or on its own on the stage of an item that has no row): the digits
/// in a paper cell with a hairline edge, a question mark while there are none. [ring] is the colour of a state ("not yet" lilac).
class EntryCell extends StatelessWidget {
  const EntryCell({super.key, required this.typed, required this.fontSize, this.ring});

  final String typed;
  final double fontSize;
  final Color? ring;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('entry-cell'),
    decoration: BoxDecoration(
      color: TokenColors.paper.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(TokenRadius.lg),
      border: Border.all(color: ring ?? TokenColors.hairline, width: 3),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            typed.isEmpty ? '?' : typed,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            softWrap: false,
            style: AppText.fixed(
              size: fontSize,
              weight: 800,
              lineHeight: 1,
              color: typed.isEmpty ? TokenColors.inkSoft : TokenColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
