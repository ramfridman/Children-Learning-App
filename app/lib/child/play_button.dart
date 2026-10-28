import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/tokens.g.dart';

/// The big round "go on" button of the child's space: an orange pebble with a dark play triangle, so that it is clear at a
/// glance what it does (a yellow button with a yellow picture on it showed nothing).
class PlayPebble extends StatelessWidget {
  const PlayPebble({super.key, required this.semanticLabel, required this.onPressed, this.size = 72});

  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => PebbleButton(
    semanticLabel: semanticLabel,
    size: size,
    fill: TokenColors.sunset,
    lip: TokenColors.sunsetDeep,
    onPressed: onPressed,
    child: Icon(Icons.play_arrow_rounded, color: TokenColors.ink, size: size * 0.62),
  );
}
