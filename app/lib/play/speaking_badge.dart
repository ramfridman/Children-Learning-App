import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

/// The speaking state of a picture in a language lesson (docs/design/l7-meet-find.md section 2): while a picture says its own word it shows
/// a sound badge at its top start corner. One rule for every picture in a language lesson, so a child learns one thing: touch a picture to
/// hear its name. It is not a button (no hit area of its own): the disc is the one of `SpeakerMark`, so the child already knows it means
/// sound. It fades in as the word starts and out a moment after it ends; with reduce motion it appears and goes at once.
class SpeakingBadge extends StatelessWidget {
  const SpeakingBadge({super.key, required this.on, this.disc = 40, this.icon = 24});

  /// The size of the badge on a tablet (the disc and its speaker).
  static const double tabletDisc = 48;
  static const double tabletIcon = 28;

  /// The badge is shown now: the word is playing.
  final bool on;
  final double disc;
  final double icon;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        key: const Key('speaking-badge'),
        opacity: on ? 1 : 0,
        duration: still ? Duration.zero : Duration(milliseconds: on ? 120 : 220),
        child: Container(
          width: disc,
          height: disc,
          decoration: BoxDecoration(
            color: TokenColors.skyTint,
            shape: BoxShape.circle,
            border: Border.all(color: TokenColors.hairline, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: TokenColors.ink.withValues(alpha: 0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.volume_up_rounded, size: icon, color: TokenColors.ink),
        ),
      ),
    );
  }
}
