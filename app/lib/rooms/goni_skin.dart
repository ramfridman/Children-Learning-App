import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';
import 'host_view.dart';

/// Goni's colours: the chameleon moment (docs/design/m11-rooms.md section 5.2). His four picture files draw his skin, shade, belly, outline
/// and four stripes in eight placeholder colours, which together are his resting look ("mint"). A [GoniSkin] swaps them while the SVG is
/// parsed (flutter_svg's [ColorMapper], so no string work and no tint that would also colour his eyes and his beret); every other colour of
/// the file stays as drawn.
///
/// The skin is chosen from ids and enums only: the name of a colour in the pack's picture ids (`asset:balloon_red` is red). No free text and
/// nothing from the child reaches it.
@immutable
class GoniSkin extends ColorMapper {
  const GoniSkin._(this.name, this._tones, this.step);

  /// The lesson colour this skin takes (one of [colours]), or `ripple`; `mint` is the resting look.
  final String name;
  final _Tones _tones;

  /// The step of the rainbow ripple, 0 to [rippleSteps] - 1 (always 0 for a colour).
  final int step;

  /// The colours of the teaching set, in `hintColours` order of the app's pictures.
  static const List<String> colours = <String>[
    'red',
    'orange',
    'yellow',
    'green',
    'blue',
    'purple',
    'pink',
    'brown',
    'black',
    'white',
    'grey',
  ];

  /// The ripple's steps, how long one lasts, and the cross-fade between two of them (under 3 Hz, section 5).
  static const int rippleSteps = 4;
  static const Duration rippleStep = Duration(milliseconds: 350);
  static const Duration rippleFade = Duration(milliseconds: 120);

  /// The colour comes in in 250 ms and goes back to mint in 400 ms (the `standard` motion of the design).
  static const Duration fadeIn = Duration(milliseconds: 250);
  static const Duration fadeOut = Duration(milliseconds: 400);

  /// His resting look: the colours the files are drawn in.
  static const GoniSkin mint = GoniSkin._('mint', _mintTones, 0);

  /// "All the colours you found": his skin stays mint and his four bands take the rainbow, one step at a time, [rippleSteps] steps in all.
  static const GoniSkin ripple = GoniSkin._('ripple', _mintTones, 0);

  /// The rainbow, in its order (the same as `rainbowOrder` of the hints).
  static const List<int> _rainbow = <int>[0xE5484D, 0xFF9F43, 0xFFD84D, 0x4CAF50, 0x2F7FE0, 0x9B6BDF];

  /// The skin of the lesson colour [colour], or null when it is not one of [colours].
  static GoniSkin? of(String? colour) {
    final _Tones? tones = _skins[colour];
    return tones == null ? null : GoniSkin._(colour!, tones, 0);
  }

  bool get isRipple => name == 'ripple';

  /// This ripple at its step [k] (wrapped into 0 to [rippleSteps] - 1).
  GoniSkin atStep(int k) => GoniSkin._(name, _tones, k % rippleSteps);

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    if (name == 'mint') return color;
    final int argb = color.toARGB32();
    if (argb >>> 24 != 0xFF) return color;
    final int rgb = argb & 0xFFFFFF;
    final int? to = switch (rgb) {
      _skinSentinel => _tones.skin,
      _shadeSentinel => _tones.shade,
      _bellySentinel => _tones.belly,
      _rimSentinel => _tones.rim,
      _ => null,
    };
    if (to != null) return Color(0xFF000000 | to);
    final int band = _stripeSentinels.indexOf(rgb);
    if (band < 0) return color;
    return Color(0xFF000000 | (isRipple ? _rainbow[(band + step) % _rainbow.length] : _tones.stripe));
  }

  @override
  bool operator ==(Object other) => other is GoniSkin && other.name == name && other.step == step;

  @override
  int get hashCode => Object.hash(name, step);

  @override
  String toString() => 'GoniSkin($name${isRipple ? ' $step' : ''})';

  // The placeholder colours of the picture files (the header of each file lists them; `GONI_SENTINEL` in make_host_poses.py).
  static const int _skinSentinel = 0x7FD3B0;
  static const int _shadeSentinel = 0x5DB894;
  static const int _bellySentinel = 0xC9EFDD;
  static const int _rimSentinel = 0x2B7A63;
  static const List<int> _stripeSentinels = <int>[0x3E9E80, 0x3E9E81, 0x3E9E82, 0x3E9E83];
}

/// One skin: its skin, shade, stripe, belly and outline colours (`GONI_SKINS` in make_host_poses.py; skin and shade are the pictures' own
/// fill and shade, so Goni turns exactly the colour of the balloon the child found).
class _Tones {
  const _Tones(this.skin, this.shade, this.stripe, this.belly, this.rim);

  final int skin;
  final int shade;
  final int stripe;
  final int belly;
  final int rim;
}

const _Tones _mintTones = _Tones(0x7FD3B0, 0x5DB894, 0x3E9E80, 0xC9EFDD, 0x2B7A63);

const Map<String, _Tones> _skins = <String, _Tones>{
  'red': _Tones(0xE5484D, 0xB8323A, 0x9A2630, 0xF6AEB0, 0x7A1C24),
  'orange': _Tones(0xFF9F43, 0xD9762A, 0xB85E1C, 0xFFD6AE, 0x8C4512),
  'yellow': _Tones(0xFFD84D, 0xE0A21A, 0xC98A10, 0xFFF1B8, 0x8A5E0A),
  'green': _Tones(0x4CAF50, 0x2F8A3A, 0x23702D, 0xAEDDB0, 0x1A5422),
  'blue': _Tones(0x2F7FE0, 0x1F5DB0, 0x184A8E, 0xA9CBF5, 0x123A70),
  'purple': _Tones(0x9B6BDF, 0x7246B8, 0x5A3596, 0xD6C4F3, 0x432672),
  'pink': _Tones(0xF48FB1, 0xD9668F, 0xC04E78, 0xFCD6E3, 0x94345A),
  'brown': _Tones(0x8A5A2B, 0x66401C, 0x4E3014, 0xC9A27C, 0x3A230E),
  // Black has lighter stripes, belly and outline, so that his bands, his edge and his mouth line still show.
  'black': _Tones(0x2B2540, 0x171424, 0x4C4568, 0x3E3858, 0x9A93BA),
  // White has a lilac-grey outline, to stand out on the pale tint, the sky and the sand.
  'white': _Tones(0xFFFFFF, 0xE2DEEC, 0xCFC9DF, 0xF4F2F8, 0x8A82A6),
  'grey': _Tones(0x9AA0B4, 0x767C92, 0x5F6579, 0xCDD0DA, 0x474C5E),
};

/// The colour an item asks the child to find: the one name of a colour in the picture ids of its right options (the last `_` part of
/// `asset:balloon_red`), or null when there is none or when there are several (a sort into bins, a rainbow order, shades such as
/// `shade_blue_2`, a pattern). The same lookup as the hints' `colourOfSprite`, on the last part only: a shade is not one colour.
String? answerColour(Activity a) {
  if (a is! TapAnswerActivity || a.correctIds.isEmpty) return null;
  final Set<String?> names = <String?>{
    for (final ChoiceOption o in a.options)
      if (a.correctIds.contains(o.id)) _colourIn(o.sprite ?? o.set?.sprite),
  };
  return names.length == 1 ? names.first : null;
}

String? _colourIn(String? sprite) {
  if (sprite == null) return null;
  final String last = sprite.replaceFirst('asset:', '').split('_').last;
  return GoniSkin.of(last) == null ? null : last;
}

/// The skin Goni takes once the child has answered [a] right: the colour found, or the ripple when the item has no single colour.
GoniSkin skinForAnswer(Activity a) => GoniSkin.of(answerColour(a)) ?? GoniSkin.ripple;

/// The skin Goni has on the lesson's card: the one colour every item of [asked] (the items the child answers) asked for, else the ripple ("all
/// the colours you found").
GoniSkin skinForLesson(Iterable<Activity> asked) {
  final Set<String?> names = <String?>{for (final Activity a in asked) answerColour(a)};
  return GoniSkin.of(names.length == 1 ? names.first : null) ?? GoniSkin.ripple;
}

/// The skins a lesson whose answered items are [asked] can need, for [precacheGoni]: each colour its items ask for, the one of the card, and the
/// ripple's steps.
Set<GoniSkin> skinsForLesson(Iterable<Activity> asked) {
  final Set<GoniSkin> skins = <GoniSkin>{
    skinForLesson(asked),
    for (final Activity a in asked) skinForAnswer(a),
  };
  return <GoniSkin>{
    for (final GoniSkin s in skins)
      if (s.isRipple)
        for (int k = 0; k < GoniSkin.rippleSteps; k++) s.atStep(k)
      else
        s,
  };
}

/// Warms the picture cache with Goni's `talk` and `celebrate` poses in [skins], so that a change of colour never shows an empty frame while
/// the picture is parsed (the cache key is the one the drawn picture makes: the app's own bundle, no theme). A failure is not an error: the
/// picture is then parsed when it is first drawn.
Future<void> precacheGoni(Iterable<GoniSkin> skins) async {
  for (final HostPose pose in <HostPose>[HostPose.celebrate, HostPose.talk]) {
    for (final GoniSkin skin in skins) {
      try {
        await SvgAssetLoader(HostSpec.goni.asset(pose), colorMapper: skin).loadBytes(null);
      } on Object {
        return;
      }
    }
  }
}
