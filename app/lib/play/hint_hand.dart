import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';

// Every hand a hint draws is one of the two widgets of this file, so that the real art drops in without a change in the
// templates: the counting hand `HintHand` and the pointing hand `PointingHand`. Each looks for its drawing in
// `assets/art/hints/` (an SVG the design-director draws) and, until the file is there, draws a plain placeholder.
//
// The files: `hand_left_<n>.svg` and `hand_right_<n>.svg` for n = 0 to 5 raised fingers, and `hand_point.svg`.
// The folder must be listed under `assets:` in pubspec.yaml when it exists.

/// Which hand: the left one fills first ("five") and the right one carries the rest.
enum HandSide { left, right }

/// The text of an art file, or null when the app has none by that name. Asked once for each name.
final Map<String, Future<String?>> _art = <String, Future<String?>>{};

Future<String?> _artFor(String path) => _art.putIfAbsent(
  path,
  () => rootBundle.loadString(path).then<String?>((String s) => s).catchError((Object _) => null),
);

/// A hand of [fingers] raised fingers (0 to 5), from the back, on [side]. Drawn at [height].
class HintHand extends StatelessWidget {
  const HintHand({super.key, required this.fingers, required this.side, this.height = 84});

  final int fingers;
  final HandSide side;
  final double height;

  /// The art file of this hand.
  static String assetOf(HandSide side, int fingers) => 'assets/art/hints/hand_${side.name}_$fingers.svg';

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _artFor(assetOf(side, fingers)),
    builder: (BuildContext context, AsyncSnapshot<String?> art) => art.data == null
        ? _Placeholder(fingers: fingers)
        : SvgPicture.string(art.data!, height: height, excludeFromSemantics: true),
  );
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

/// The helper's pointing hand (hint 3, from part 2 of B-40 on): one neutral hand for every companion, the fingertip at the top
/// left of the picture. Drawn at [height].
class PointingHand extends StatelessWidget {
  const PointingHand({super.key, this.height = 66});

  final double height;

  /// The art file of the pointing hand.
  static const String asset = 'assets/art/hints/hand_point.svg';

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _artFor(asset),
    builder: (BuildContext context, AsyncSnapshot<String?> art) => art.data == null
        ? SizedBox(
            key: const Key('pointing-hand-placeholder'),
            height: height,
            width: height * 2 / 3,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: TokenColors.skyTint,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.fromBorderSide(BorderSide(color: TokenColors.skyDeep, width: 2.6)),
              ),
            ),
          )
        : SvgPicture.string(art.data!, height: height, excludeFromSemantics: true),
  );
}
