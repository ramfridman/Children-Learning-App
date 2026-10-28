import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart';
import '../app/reward_providers.dart';
import '../characters/character.dart';
import '../characters/character_view.dart';
import '../child/companion_views.dart';
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/outfits.dart';
import '../strings/he.dart';
import 'trophy_art.dart';

/// What the ceremony says for a trophy tier, and for a medal.
Str ceremonyLine(TrophyTier? tier) => switch (tier) {
  TrophyTier.bronze => He.ceremonyBronze,
  TrophyTier.silver => He.ceremonySilver,
  TrophyTier.gold => He.ceremonyGold,
  null => He.ceremonyMedal,
};

/// The voice line of the ceremony (`vo:core.ceremony.<tier>`); until it is recorded the line is only written, and the
/// voice player treats a line with no recording as silence.
String ceremonyVoice(TrophyTier? tier) => 'vo:core.ceremony.${tier?.name ?? 'medal'}';

const Color _stageColour = Color(0xFF5E4E96);

/// The ceremony for a trophy or a medal (PLAN: the ceremony; M8 D2). The lights dim, a spotlight falls, the cup spins in
/// with confetti and the companion says its line. It is drawn in code. With "reduce motion" it is a still spotlight and a
/// fade. A tap anywhere ends it after a moment, the button always does, and there is no timer on screen.
class CeremonyScreen extends ConsumerStatefulWidget {
  const CeremonyScreen({super.key, required this.awardKey, this.prize});

  /// The award being celebrated: a trophy key or a medal key.
  final String awardKey;

  /// A prize that comes with it (the first trophy of its tier), shown on a card, or null.
  final Outfit? prize;

  @override
  ConsumerState<CeremonyScreen> createState() => _CeremonyScreenState();
}

class _CeremonyScreenState extends ConsumerState<CeremonyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _started = false;

  ({TrophyLand land, TrophyTier tier})? get _trophy => Awards.trophyOf(widget.awardKey);
  String? get _medal => Awards.medalOf(widget.awardKey);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _play.value = 1;
    } else {
      _play.forward();
    }
    // The companion says its line as the cup arrives. A line with no recording is silence.
    unawaited(ref.read(voiceDirectorProvider).say(ceremonyVoice(_trophy?.tier)));
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop();

  /// A tap anywhere ends the ceremony, but only after a moment (the first quarter of it), so that a tap that was still on
  /// its way from the lesson does not. With "reduce motion" it is complete from the start.
  void _tapAnywhere() {
    if (_play.value >= 0.28) _done();
  }

  @override
  Widget build(BuildContext context) {
    final ({TrophyLand land, TrophyTier tier})? trophy = _trophy;
    final String? medal = _medal;
    final TrophyTier? tier = trophy?.tier;
    final Str title = trophy != null ? trophyName(trophy.tier) : medalWords(medal ?? '').name;
    final AsyncValue<Character> friend = ref.watch(characterForRoleProvider(CharacterRole.celebrationCameo));
    final Outfit? worn = wornOutfit(ref.watch(outfitProvider));
    return Scaffold(
      backgroundColor: _stageColour,
      body: GestureDetector(
        key: const Key('ceremony'),
        behavior: HitTestBehavior.opaque,
        onTap: _tapAnywhere,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final double h = box.maxHeight;
              final double w = box.maxWidth;
              return AnimatedBuilder(
                animation: _play,
                builder: (BuildContext context, Widget? _) {
                  final double t = _play.value;
                  final double fade = Curves.easeOut.transform((t / 0.25).clamp(0.0, 1.0));
                  final double arrive = Curves.easeOutBack.transform(((t - 0.1) / 0.5).clamp(0.0, 1.0));
                  final double spin = Curves.easeOutCubic.transform(((t - 0.1) / 0.6).clamp(0.0, 1.0));
                  final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                  final double cup = h * 0.48;
                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: CustomPaint(painter: SpotlightPainter(strength: fade)),
                      ),
                      if (!reduced)
                        Positioned.fill(
                          child: CustomPaint(painter: ConfettiPainter(progress: t)),
                        ),
                      // The title.
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: fade,
                          child: Center(
                            child: Container(
                              key: const Key('ceremony-title'),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                              decoration: BoxDecoration(
                                color: TokenColors.paper,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: softShadow,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const BoardSvg('assets/art/world/star_gold.svg', width: 26, height: 26),
                                  const SizedBox(width: 10),
                                  Text('${title.text}!', style: AppText.fixed(size: 30, weight: 700)),
                                  const SizedBox(width: 10),
                                  const BoardSvg('assets/art/world/star_gold.svg', width: 26, height: 26),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // The cup (or medal) spins in over its stand.
                      Positioned(
                        left: (w - cup) / 2,
                        top: h * 0.2 + (1 - arrive) * 30,
                        width: cup,
                        height: cup,
                        child: Opacity(
                          opacity: reduced ? fade : arrive.clamp(0.0, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(reduced ? 0 : (1 - spin) * math.pi * 2)
                              ..scaleByDouble(0.6 + 0.4 * arrive, 0.6 + 0.4 * arrive, 1.0, 1.0),
                            child: Center(
                              child: trophy != null
                                  ? TrophyCup(land: trophy.land, tier: trophy.tier, height: cup)
                                  : MedalArt(id: medal ?? '', height: cup),
                            ),
                          ),
                        ),
                      ),
                      // The companion, who presents it.
                      PositionedDirectional(
                        start: 16,
                        top: h * 0.22,
                        width: h * 0.46,
                        height: h * 0.46,
                        child: Opacity(
                          opacity: fade,
                          child: friend.value == null
                              ? const SizedBox.shrink()
                              : SpeakingCharacter(
                                  character: friend.value!,
                                  director: ref.read(voiceDirectorProvider),
                                  resting: CharacterState.celebrate,
                                  voiceOf: friend.value!.id,
                                  outfit: worn,
                                ),
                        ),
                      ),
                      // The prize that comes with it, on a card.
                      if (widget.prize != null)
                        PositionedDirectional(
                          end: 16,
                          top: h * 0.2,
                          child: Opacity(
                            opacity: fade,
                            child: Transform.rotate(
                              angle: -0.07,
                              child: _PrizeCard(prize: widget.prize!, friend: friend.value),
                            ),
                          ),
                        ),
                      // What the companion says.
                      Positioned(
                        left: w * 0.18,
                        right: w * 0.18,
                        bottom: 14,
                        child: Opacity(
                          opacity: fade,
                          child: Container(
                            key: const Key('ceremony-line'),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: TokenColors.paper,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: softShadow,
                            ),
                            child: Text(
                              ceremonyLine(tier).text,
                              textAlign: TextAlign.center,
                              style: AppText.fixed(size: 22, weight: 600),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 16,
                        bottom: 14,
                        child: PebbleButton(
                          key: const Key('ceremony-continue'),
                          semanticLabel: He.ceremonyContinueSemantics.text,
                          size: 64,
                          fill: TokenColors.spark,
                          lip: TokenColors.sparkDeep,
                          onPressed: _done,
                          child: const BoardSvg('assets/art/ui/spark.svg', width: 32, height: 32),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({required this.prize, required this.friend});

  final Outfit prize;
  final Character? friend;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('ceremony-prize'),
    width: 150,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: TokenColors.paper,
      borderRadius: BorderRadius.circular(TokenRadius.xl),
      boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(He.ceremonyAlso.text, style: AppText.fixed(size: 16, weight: 600)),
        const SizedBox(height: 4),
        SizedBox(
          width: 90,
          height: 90,
          child: friend == null
              ? const SizedBox.shrink()
              : CharacterView(character: friend!, state: CharacterState.idle, outfit: prize),
        ),
        Text(prize.name.text, style: AppText.fixed(size: 16, weight: 600)),
      ],
    ),
  );
}

/// The dim stage and the cone of light that falls on the cup.
class SpotlightPainter extends CustomPainter {
  const SpotlightPainter({required this.strength});

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final Path cone = Path()
      ..moveTo(size.width * 0.43, 0)
      ..lineTo(size.width * 0.57, 0)
      ..lineTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.26, size.height)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFF3C4).withValues(alpha: 0.10 * strength),
            const Color(0xFFFFF3C4).withValues(alpha: 0.38 * strength),
          ],
        ).createShader(Offset.zero & size),
    );
    final Rect stand = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.71),
      width: size.width * 0.34,
      height: size.height * 0.09,
    );
    canvas.drawOval(stand, Paint()..color = const Color(0xFFE0B97C).withValues(alpha: strength));
  }

  @override
  bool shouldRepaint(SpotlightPainter old) => old.strength != strength;
}

/// Confetti that falls once. Fixed positions and colours (no chance in it): the same ceremony looks the same every time.
class ConfettiPainter extends CustomPainter {
  const ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> _colours = <Color>[
    Color(0xFFFFC83D),
    Color(0xFFF46A5E),
    Color(0xFF34A86A),
    Color(0xFF6BB8F0),
    Color(0xFFE04F9E),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double t = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
    if (t <= 0) return;
    for (int i = 0; i < 42; i++) {
      final double x = (math.sin(i * 12.9898) * 0.5 + 0.5) * size.width;
      final double speed = 0.55 + (math.sin(i * 78.233) * 0.5 + 0.5) * 0.45;
      final double y = -20 + t * speed * (size.height + 40);
      final double spin = i * 0.7 + t * 6 * speed;
      canvas.save();
      canvas.translate(x + math.sin(t * 5 + i) * 10, y);
      canvas.rotate(spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2.5, 10, 5), const Radius.circular(1.5)),
        Paint()..color = _colours[i % _colours.length].withValues(alpha: (1 - t * 0.6).clamp(0.0, 1.0)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => old.progress != progress;
}
