import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'goni_skin.dart';

/// What a host is doing: its still, or one of the three poses of step 1.2. Until a host has the `show` pose in a lesson (Stage 2) only the
/// others are drawn.
enum HostPose { idle, talk, show, celebrate }

/// One of the nine hosts: where its pictures are and where its mouth is (the place the bubble's tail points at, from the anchors written
/// in each pose file, in the 512 by 512 units of the artboard). The pictures face the task (left) and are never mirrored.
class HostSpec {
  const HostSpec._(this.id, {required this.talkMouth, required this.showMouth});

  final String id;

  /// The mouth in the `talk` pose and in the `show` pose. The still (`idle`) shares the `talk` mouth, and `celebrate` has none (nobody
  /// speaks from it).
  final Offset talkMouth;
  final Offset showMouth;

  static const double artboard = 512;

  /// Where the figure of a pose is in the artboard, as shares of its height (design/assets, measured on all 36 pictures: a test does it
  /// again): the feet stand at 474 of 512, and nothing of any pose rises above 8 of 512 (the tallest is the giraffe's celebrate, whose head
  /// is at 11). A place that must hold a whole pose fits these, not the box.
  static const double feetShare = 474 / artboard;
  static const double topShare = 8 / artboard;

  String asset(HostPose pose) => 'assets/art/hosts/${id}_${pose.name}.svg';

  /// The mouth as a share of the box the host is drawn in (0 to 1 each way).
  Offset mouthShare(HostPose pose) => (pose == HostPose.show ? showMouth : talkMouth) / artboard;

  static const HostSpec nekudi = HostSpec._(
    'nekudi',
    talkMouth: Offset(256, 268),
    showMouth: Offset(252, 262),
  );
  static const HostSpec goni = HostSpec._('goni', talkMouth: Offset(138, 352), showMouth: Offset(140, 324));
  static const HostSpec kubi = HostSpec._('kubi', talkMouth: Offset(101, 344), showMouth: Offset(104, 296));
  static const HostSpec timi = HostSpec._('timi', talkMouth: Offset(254, 340), showMouth: Offset(252, 338));
  static const HostSpec tzaadon = HostSpec._(
    'tzaadon',
    talkMouth: Offset(262, 236),
    showMouth: Offset(254, 240),
  );
  static const HostSpec pnina = HostSpec._('pnina', talkMouth: Offset(150, 232), showMouth: Offset(140, 238));
  static const HostSpec eng = HostSpec._(
    'host_eng',
    talkMouth: Offset(257, 222),
    showMouth: Offset(254, 224),
  );
  static const HostSpec heb = HostSpec._(
    'host_heb',
    talkMouth: Offset(256, 276),
    showMouth: Offset(254, 280),
  );
  static const HostSpec rus = HostSpec._(
    'host_rus',
    talkMouth: Offset(238, 197),
    showMouth: Offset(200, 210),
  );

  static const List<HostSpec> all = <HostSpec>[nekudi, goni, kubi, timi, tzaadon, pnina, eng, heb, rus];

  static HostSpec byId(String id) => all.firstWhere((HostSpec h) => h.id == id);
}

/// Draws a host in a pose, cross-fading when the pose changes and hopping once as it starts to celebrate. With "reduce motion" nothing
/// moves: the picture only changes.
///
/// Goni may also wear a [skin] (docs/design/m11-rooms.md section 5.2): the colour the child just found, or the rainbow ripple. It comes in
/// with a cross-fade of 250 ms, goes back to mint in 400 ms, and the ripple steps every 350 ms with 120 ms between steps; with "reduce
/// motion" there is the same cross-fade and no ripple (one still rainbow frame). A host that appears already wearing a skin (the lesson's
/// card) arrives in mint and takes it a moment later, or at once with "reduce motion". Another host ignores it.
class HostView extends StatefulWidget {
  const HostView({
    super.key,
    required this.host,
    this.pose = HostPose.idle,
    this.semanticLabel,
    this.skin,
    this.hop = true,
  });

  final HostSpec host;
  final HostPose pose;

  /// Goni's colour, or null for his resting mint. A [GoniSkin.ripple] is stepped here.
  final GoniSkin? skin;

  /// The celebrate pose hops as it starts. Off where the change of pose comes with a motion of its own (the Show's last step, where the stage's
  /// landmark reacts).
  final bool hop;

  /// How high the hop of the celebrate pose lifts the picture, as a share of its box.
  static const double hopLift = 0.07;

  /// The cross-fade of a change of pose alone.
  static const Duration poseFade = Duration(milliseconds: 140);

  /// What a screen reader says for the host; null for a host that is only decoration at the moment.
  final String? semanticLabel;

  @override
  State<HostView> createState() => _HostViewState();
}

class _HostViewState extends State<HostView> with TickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  /// The ripple's clock: [GoniSkin.rippleSteps] steps of [GoniSkin.rippleStep], then it holds the last one.
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: GoniSkin.rippleStep * GoniSkin.rippleSteps,
  );

  bool _reduced = false;
  bool _checked = false;

  /// The host has just appeared wearing a skin: it shows mint for the first frame and the skin is cross-faded in after it.
  bool _arriving = false;

  /// What was drawn last, to know what kind of change the next picture is, and the cross-fade of that change.
  GoniSkin? _drawn;
  HostPose? _drawnPose;
  Duration _fade = HostView.poseFade;

  bool get _recolours => widget.host == HostSpec.goni;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_checked) return;
    _checked = true;
    if (_recolours && widget.skin != null && !_reduced) {
      _arriving = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _arriving = false);
        _startRipple();
      });
    } else {
      _startRipple();
    }
  }

  @override
  void didUpdateWidget(HostView old) {
    super.didUpdateWidget(old);
    if (widget.hop && widget.pose == HostPose.celebrate && old.pose != HostPose.celebrate && !_reduced) {
      _hop.forward(from: 0);
    }
    if (widget.skin != old.skin) _startRipple();
  }

  void _startRipple() {
    final GoniSkin? skin = widget.skin;
    if (_recolours && skin != null && skin.isRipple && !_reduced) {
      _ripple.forward(from: 0);
    } else {
      _ripple.stop();
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    _ripple.dispose();
    super.dispose();
  }

  /// The skin to draw now: the skin asked for, its ripple at the step of the moment, or mint while the host is arriving.
  GoniSkin? get _skinNow {
    final GoniSkin? skin = widget.skin;
    if (!_recolours || skin == null || _arriving) return null;
    if (!skin.isRipple) return skin;
    return skin.atStep(
      _reduced ? 0 : math.min(GoniSkin.rippleSteps - 1, (_ripple.value * GoniSkin.rippleSteps).floor()),
    );
  }

  /// How long the cross-fade to [skin] takes: 400 ms back to mint, 120 ms from one ripple step to the next, 250 ms into a colour, and
  /// 140 ms for a change of pose alone.
  Duration _fadeTo(GoniSkin? skin) {
    final GoniSkin? from = _drawn;
    if (skin == from) return HostView.poseFade;
    if (skin == null) return GoniSkin.fadeOut;
    if (from != null && from.isRipple && skin.isRipple) return GoniSkin.rippleFade;
    return GoniSkin.fadeIn;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: widget.semanticLabel == null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_hop, _ripple]),
          builder: (BuildContext context, Widget? _) {
            final GoniSkin? skin = _skinNow;
            if (skin != _drawn || widget.pose != _drawnPose) {
              if (_drawnPose != null) _fade = _fadeTo(skin);
              _drawn = skin;
              _drawnPose = widget.pose;
            }
            // Two small hops, one after the other, with the shadow staying on the ground (the picture is lifted as a whole, softly).
            final double lift = _hop.isAnimating
                ? -(math.sin(_hop.value * 4 * math.pi).abs()) * HostView.hopLift
                : 0;
            return FractionalTranslation(
              translation: Offset(0, lift),
              child: AnimatedSwitcher(
                duration: _fade,
                child: SvgPicture.asset(
                  widget.host.asset(widget.pose),
                  key: ValueKey<(HostPose, GoniSkin?)>((widget.pose, skin)),
                  colorMapper: skin,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
