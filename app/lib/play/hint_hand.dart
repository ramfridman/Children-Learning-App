import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';

// Every hand a hint draws is one of the two widgets of this file: the counting hand `HintHand` and the pointing hand
// `PointingHand`. Each draws the design-director's art from `assets/art/hints/` (13 SVG files, listed under `assets:` in
// pubspec.yaml), sized by its height with the aspect kept. A plain placeholder is drawn only when a file is missing, so a missing
// asset never breaks a lesson.
//
// The files: `hand_left_<n>.svg` and `hand_right_<n>.svg` for n = 0 to 5 raised fingers (viewBox 112 x 174), and `hand_point.svg`
// (viewBox 102 x 142, the fingertip at (37.9, 127.5)).

/// Which hand: the left one fills first ("five") and the right one carries the rest.
enum HandSide { left, right }

/// The text of an art file, or null when the app has none by that name. Asked once for each name.
final Map<String, Future<String?>> _art = <String, Future<String?>>{};

/// The files that have been read: a hand drawn after [warmHintHands] needs no waiting, so it never flashes the placeholder.
final Map<String, String?> _loaded = <String, String?>{};

Future<String?> _artFor(String path) => _art.putIfAbsent(path, () => _read(path));

/// Draws the art of [path] at [height] (its width follows the art's aspect), or [placeholder] where there is none.
Widget _drawn(String path, double height, Widget placeholder) {
  Widget svg(String? art) =>
      art == null ? placeholder : SvgPicture.string(art, height: height, excludeFromSemantics: true);
  if (_loaded.containsKey(path)) return svg(_loaded[path]);
  return FutureBuilder<String?>(
    future: _artFor(path),
    builder: (BuildContext context, AsyncSnapshot<String?> art) => svg(art.data),
  );
}

/// Reads one art file, and remembers what it found (null when there is none).
Future<String?> _read(String path) async {
  try {
    return _loaded[path] = await rootBundle.loadString(path);
  } catch (_) {
    return _loaded[path] = null;
  }
}

/// Loads every hand of the folder, so that a hint finds them ready (and a test can wait for them). Asking again reads them again;
/// nothing a hand widget asked for earlier is waited for, so this finishes even where that never would (a test's fake clock).
Future<void> warmHintHands() async {
  await Future.wait(<Future<String?>>[
    _read(PointingHand.asset),
    for (final HandSide side in HandSide.values)
      for (int n = 0; n <= 5; n++) _read(HintHand.assetOf(side, n)),
  ]);
}

/// A hand of [fingers] raised fingers (0 to 5), from the back, on [side]. Drawn at [height] (84 on a phone, 116 on a tablet; the
/// width follows from the art's aspect, 54 on a phone).
class HintHand extends StatelessWidget {
  const HintHand({super.key, required this.fingers, required this.side, this.height = 84});

  final int fingers;
  final HandSide side;
  final double height;

  /// The art file of this hand.
  static String assetOf(HandSide side, int fingers) => 'assets/art/hints/hand_${side.name}_$fingers.svg';

  /// The drawing box of every counting hand.
  static const Size artSize = Size(112, 174);

  /// A point just inside the tip of raised finger [finger] (0 index, 1 middle, 2 ring, 3 little, 4 thumb: the order they rise)
  /// of the hand on [side], in the art's own units. From the finger table of `docs/design/b40/make_hint_hands.py` (the right
  /// hand is the left one mirrored). A hint draws its dotted link from a counted thing to this point.
  static Offset tipInArt(HandSide side, int finger) {
    const List<Offset> left = <Offset>[
      Offset(71.6, 21),
      Offset(51.5, 11),
      Offset(31.3, 20),
      Offset(11.8, 42.5),
      Offset(101.4, 83.3),
    ];
    final Offset p = left[finger.clamp(0, 4)];
    return side == HandSide.left ? p : Offset(artSize.width - p.dx, p.dy);
  }

  @override
  Widget build(BuildContext context) =>
      _drawn(assetOf(side, fingers), height, _Placeholder(fingers: fingers));
}

/// The stand-in hand: five bars on a palm. A finger that is up is `spark`, one that is folded a short stub. Each up finger has the key
/// `finger-up`, so the tests can count what a hint shows.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.fingers});

  final int fingers;

  static const double _fingerW = 11;
  static const double _up = 52;
  static const double _folded = 14;

  @override
  Widget build(BuildContext context) {
    // With "reduce motion" a finger is up or down at once, in the same order, with no rise.
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int f = 0; f < 5; f++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  key: f < fingers ? const Key('finger-up') : const Key('finger-down'),
                  duration: still ? Duration.zero : const Duration(milliseconds: 250),
                  width: _fingerW,
                  height: f < fingers ? _up : _folded,
                  decoration: BoxDecoration(
                    color: f < fingers ? TokenColors.spark : TokenColors.mist,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: TokenColors.ink, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        Container(
          width: 5 * (_fingerW + 3),
          height: 20,
          decoration: BoxDecoration(
            color: TokenColors.sparkTint,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: TokenColors.ink, width: 1.5),
          ),
        ),
      ],
    );
  }
}

/// The helper's pointing hand (hint 3): one neutral hand for every companion, coming from the guide's side (the upper right).
/// Drawn at [height] (72 on a phone, 96 on a tablet, never under 40). Put the fingertip on a target with [tipAt].
class PointingHand extends StatelessWidget {
  const PointingHand({super.key, this.height = 72});

  final double height;

  /// The art file of the pointing hand, its drawing box, and where the fingertip is in it.
  static const String asset = 'assets/art/hints/hand_point.svg';
  static const Size artSize = Size(102, 142);
  static const Offset artTip = Offset(37.9, 127.5);

  /// The width of the hand drawn at [height].
  static double widthAt(double height) => height * artSize.width / artSize.height;

  /// Where the fingertip is inside a hand drawn at [height], from the hand's top left corner.
  static Offset tipAt(double height) => artTip * (height / artSize.height);

  @override
  Widget build(BuildContext context) => _drawn(
    asset,
    height,
    SizedBox(
      key: const Key('pointing-hand-placeholder'),
      height: height,
      width: widthAt(height),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: TokenColors.skyTint,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(BorderSide(color: TokenColors.skyDeep, width: 2.6)),
        ),
      ),
    ),
  );
}
