import 'package:flutter/material.dart';

import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';

/// The avatars a parent can choose from in M1 (the three from the design boards).
const List<String> avatarIds = <String>['avatar-noa', 'avatar-itai', 'avatar-tamar'];

/// A child's round avatar picture.
class AvatarPicture extends StatelessWidget {
  const AvatarPicture({super.key, required this.avatarId, required this.size});

  final String avatarId;
  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: BoardSvg('assets/art/$avatarId.svg', width: size, height: size, fit: BoxFit.cover),
    ),
  );
}

/// The round avatar button of the home screen (board 10): a [diameter] pebble with a white ring and
/// the picture inside. Pressing it brings back the profile picker.
class AvatarButton extends StatelessWidget {
  const AvatarButton({
    super.key,
    required this.avatarId,
    required this.diameter,
    required this.label,
    required this.onPressed,
  });

  final String avatarId;
  final double diameter;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PebbleButton(
    key: const Key('home-avatar'),
    size: diameter,
    semanticLabel: label,
    onPressed: onPressed,
    fill: TokenColors.paper,
    child: AvatarPicture(avatarId: avatarId, size: diameter - 8),
  );
}
