import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/reward_providers.dart';
import '../data/app_database.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/sticker_design.dart';
import '../strings/he.dart';

/// Sticker Island: every sticker the child has earned, one for each lesson finished. Nothing is locked and nothing is ever
/// taken away; a child who has none yet sees a calm island and one line.
class StickerIsland extends ConsumerWidget {
  const StickerIsland({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Reward> stickers = ref.watch(stickersProvider(childId)).value ?? const <Reward>[];
    return Scaffold(
      backgroundColor: TokenColors.worldSea1,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(TokenRadius.xl),
                    boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
                  ),
                  child: stickers.isEmpty
                      ? Text(
                          He.stickersEmpty.text,
                          key: const Key('stickers-empty'),
                          textAlign: TextAlign.center,
                          style: AppText.fixed(size: 22, weight: 600),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              for (final Reward r in stickers)
                                BoardSvg(
                                  stickerAsset(r.awardKey),
                                  key: Key('sticker-${r.awardKey}'),
                                  width: 84,
                                  height: 84,
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              top: 8,
              child: PebbleButton(
                key: const Key('stickers-back'),
                semanticLabel: He.landBackSemantics.text,
                size: 48,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: () => Navigator.of(context).pop(),
                child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
