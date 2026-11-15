import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// What a host is doing: its still, or one of the three poses of step 1.2. Until a host has the `show` pose in a lesson (Stage 2) only the
/// others are drawn.
enum HostPose { idle, talk, show, celebrate }

/// One of the nine hosts: where its pictures are and where its mouth is (the place the bubble's tail points at, from the anchors written
/// in each pose file, in the 512 by 512 units of the artboard). The pictures face the task (left) and are never mirrored.
class HostSpec {
  const HostSpec._(this.id, {required this.talkMouth, required this.showMouth, this.safe = false});

  final String id;

  /// The mouth in the `talk` pose and in the `show` pose. The still (`idle`) shares the `talk` mouth, and `celebrate` has none (nobody
  /// speaks from it).
  final Offset talkMouth;
  final Offset showMouth;

  /// Goni's pictures are the colour-safe ones: nothing of the host competes with the colours being taught (spec 3.1).
  final bool safe;

  static const double artboard = 512;

  String asset(HostPose pose) => 'assets/art/hosts/${id}_${pose.name}${safe ? '_safe' : ''}.svg';

  /// The mouth as a share of the box the host is drawn in (0 to 1 each way).
  Offset mouthShare(HostPose pose) => (pose == HostPose.show ? showMouth : talkMouth) / artboard;

  static const HostSpec nekudi = HostSpec._(
    'nekudi',
    talkMouth: Offset(256, 268),
    showMouth: Offset(252, 262),
  );
  static const HostSpec goni = HostSpec._(
    'goni',
    talkMouth: Offset(138, 352),
    showMouth: Offset(140, 324),
    safe: true,
  );
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
class HostView extends StatefulWidget {
  const HostView({super.key, required this.host, this.pose = HostPose.idle, this.semanticLabel});

  final HostSpec host;
  final HostPose pose;

  /// What a screen reader says for the host; null for a host that is only decoration at the moment.
  final String? semanticLabel;

  @override
  State<HostView> createState() => _HostViewState();
}

class _HostViewState extends State<HostView> with SingleTickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didUpdateWidget(HostView old) {
    super.didUpdateWidget(old);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.pose == HostPose.celebrate && old.pose != HostPose.celebrate && !reduced) {
      _hop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget picture = AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: SvgPicture.asset(
        widget.host.asset(widget.pose),
        key: ValueKey<HostPose>(widget.pose),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: widget.semanticLabel == null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _hop,
          child: picture,
          builder: (BuildContext context, Widget? child) {
            // Two small hops, one after the other, with the shadow staying on the ground (the picture is lifted as a whole, softly).
            final double lift = _hop.isAnimating ? -(math.sin(_hop.value * 4 * math.pi).abs()) * 0.07 : 0;
            return FractionalTranslation(translation: Offset(0, lift), child: child);
          },
        ),
      ),
    );
  }
}
