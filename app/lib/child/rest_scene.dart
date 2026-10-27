import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

/// What a child sees when it is time to rest (the parent's rest hours, schedule or daily limit, with "lock" on): the
/// sea, a gentle sentence, and one way back. No number, no clock, nothing that counts down, and no word about why.
class RestScene extends StatelessWidget {
  const RestScene({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('rest-scene'),
    backgroundColor: TokenColors.worldSea1,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                He.restScene.text,
                textAlign: TextAlign.center,
                style: AppText.fixed(size: 30, weight: 700, lineHeight: 1.7, display: true),
              ),
              const SizedBox(height: 36),
              PebbleButton(
                semanticLabel: He.restBackSemantics.text,
                onPressed: onBack,
                size: 72,
                child: const Icon(Icons.arrow_forward_rounded, size: 34, color: TokenColors.ink),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
