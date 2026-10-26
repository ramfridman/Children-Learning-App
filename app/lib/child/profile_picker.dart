import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';

/// "Who is playing now?" (board 11). Siblings share the device, so every child has a card. The "+"
/// card leads to the parent gate: children cannot add or remove profiles.
class ProfilePicker extends StatelessWidget {
  const ProfilePicker({super.key, required this.profiles, required this.onChoose, required this.onAdd});

  final List<Profile> profiles;
  final void Function(Profile) onChoose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              He.pickerTitle.text,
              style: AppText.kid(TokenType.title[layout.band]!, tablet: layout.isTablet),
            ),
            SizedBox(height: layout.isTablet ? 40 : 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: layout.isTablet ? 40 : 24,
              runSpacing: 16,
              children: <Widget>[
                for (final Profile p in profiles) _ProfileCard(profile: p, onTap: () => onChoose(p)),
                _AddCard(onTap: onAdd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double size = layout.isTablet ? 150 : 104;
    return Semantics(
      button: true,
      label: profile.name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AvatarBadge(avatarId: profile.avatar, size: size),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(profile.name, style: AppText.kid(TokenType.label, tablet: layout.isTablet)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    final double size = layout.isTablet ? 150 : 104;
    return Semantics(
      button: true,
      label: He.pickerAddSemantics.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: TokenColors.mist,
            shape: BoxShape.circle,
            border: Border.all(color: TokenColors.sketch, width: TokenBorder.medium),
          ),
          child: const Icon(Icons.add_rounded, size: 44, color: TokenColors.inkSoft),
        ),
      ),
    );
  }
}
