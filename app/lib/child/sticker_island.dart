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
                  margin: const EdgeInsets.fromLTRB(24, 64, 24, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(TokenRadius.xl),
                    boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          stickers.isEmpty ? He.stickersEmptyChild.text : He.stickersHow.text,
                          key: stickers.isEmpty ? const Key('stickers-empty') : const Key('stickers-how'),
                          textAlign: TextAlign.center,
                          style: AppText.fixed(size: 20, weight: 600),
                        ),
                        const SizedBox(height: 12),
                        // An album page: the stickers there are, and the empty places waiting for the next ones.
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 14,
                          runSpacing: 14,
                          children: <Widget>[
                            for (final Reward r in stickers)
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: softShadow,
                                  color: TokenColors.paper,
                                ),
                                child: BoardSvg(
                                  stickerAsset(r.awardKey),
                                  key: Key('sticker-${r.awardKey}'),
                                  width: 76,
                                  height: 76,
                                ),
                              ),
                            for (int i = stickers.length; i < _places(stickers.length); i++)
                              Container(
                                key: Key('sticker-place-$i'),
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: TokenColors.mist,
                                  border: Border.all(color: TokenColors.cardLip, width: 3),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  key: const Key('stickers-title'),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: softShadow,
                  ),
                  child: Text(He.stickersTitle.text, style: AppText.fixed(size: 24, weight: 700)),
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

/// How many places the album page shows: the stickers there are and room for the next ones, in whole rows of six, never
/// fewer than six.
int _places(int have) => have < 6 ? 6 : ((have ~/ 6) + 1) * 6;
