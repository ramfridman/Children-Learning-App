import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/tokens.g.dart';

/// The avatars a parent can choose from in M1 (the three from the design boards).
const List<String> avatarIds = <String>['avatar-noa', 'avatar-itai', 'avatar-tamar'];

/// Nitzi in one of her poses. Static drawing for now; M4 brings the character system.
class NitziArt extends StatelessWidget {
  const NitziArt({super.key, this.pose = 'idle', this.height = 200});

  final String pose;
  final double height;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/art/nitzi-$pose.svg',
    height: height,
    width: height,
    excludeFromSemantics: true,
  );
}

/// A child's round avatar picture, with a paper ring like the profile button on board 10.
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.avatarId, this.size = 64});

  final String avatarId;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(4),
    decoration: const BoxDecoration(color: TokenColors.paper, shape: BoxShape.circle),
    child: ClipOval(
      child: SvgPicture.asset(
        'assets/art/$avatarId.svg',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        placeholderBuilder: (BuildContext _) => const ColoredBox(color: TokenColors.mist),
      ),
    ),
  );
}
