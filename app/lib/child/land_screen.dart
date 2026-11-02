import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/companion.dart' show voiceDirectorProvider;
import '../app/reward_providers.dart';
import '../app/world_providers.dart';
import '../content/models.dart';
import '../data/app_database.dart' show Reward;
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../rewards/award.dart';
import '../rewards/reward_rules.dart';
import '../strings/he.dart';
import '../voice/voice_director.dart';
import '../voice/voice_lines.dart';
import 'play_button.dart';
import 'trophy_art.dart' show landOf;
import '../world/world_art.dart';
import '../world/world_state.dart';

/// One land close up: its island with an object for each skill, growing as the child understands, and a way into the
/// lesson. A bell flag on an object means a check is due ("someone is calling for help"); tapping it opens a short
/// mission of three to five items, made on the spot. Nothing here is locked, timed or counted against the child.
class LandScreen extends ConsumerStatefulWidget {
  const LandScreen({super.key, required this.childId, required this.land, this.onPlay, this.onMission});

  final String childId;
  final TrophyLand land;

  /// Opens the land's lesson (null when the land has none).
  final VoidCallback? onPlay;

  /// Opens a revisit mission for one skill.
  final void Function(Lesson mission)? onMission;

  @override
  ConsumerState<LandScreen> createState() => _LandScreenState();
}

class _LandScreenState extends ConsumerState<LandScreen> {
  /// The skill whose drawing was touched last: its name and where it stands show on a card.
  String? _picked;

  /// Read once: the screen's own voice must still be reachable when it is closed (a `ref` is not, in [dispose]).
  late final VoiceDirector _director;
  bool _prefetched = false;

  @override
  void initState() {
    super.initState();
    _director = ref.read(voiceDirectorProvider);
    // The lines of the map cards are a part of the narrator's voice that is not kept in memory: it is read when the island
    // opens (as a lesson reads its own), so that the first touch is heard at once.
    ref.listenManual<AsyncValue<WorldView>>(worldProvider(childId), (_, AsyncValue<WorldView> next) {
      final WorldView? view = next.value;
      if (_prefetched || view == null) return;
      _prefetched = true;
      unawaited(_director.prefetch(cardLineVoiceIds(view.lands[land] ?? const <WorldObject>[])));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    // Leaving the island stops the card's line, and only that: the next screen's own line is not touched.
    unawaited(_director.stopFor(this));
    super.dispose();
  }

  /// A touch on a drawing: its card opens and, if the card shows the skill's own line, the narrator says it. Touching the
  /// drawing again closes the card and stops the line, and touching another one replaces it (the voice never overlaps).
  void _pick(WorldObject o) {
    final bool open = _picked != o.skillId;
    setState(() => _picked = open ? o.skillId : null);
    final String? voice = open && o.line != null ? skillLineVoiceId(o.skillId) : null;
    if (voice == null) {
      unawaited(_director.stopFor(this));
    } else {
      unawaited(_director.say(voice, owner: this));
    }
  }

  String get childId => widget.childId;
  TrophyLand get land => widget.land;
  VoidCallback? get onPlay => widget.onPlay;
  void Function(Lesson mission)? get onMission => widget.onMission;

  @override
  Widget build(BuildContext context) {
    final WorldView? view = ref.watch(worldProvider(childId)).value;
    final List<WorldObject> objects = view?.lands[land] ?? const <WorldObject>[];
    final WorldObject? picked = objects.where((WorldObject o) => o.skillId == _picked).firstOrNull;
    // The island decorations the child has earned (10, 20 and 30 skills understood for good) stand on every island.
    final Set<String> given = <String>{
      for (final Reward r in ref.watch(rewardsProvider(childId)).value ?? const <Reward>[]) r.awardKey,
    };
    final ({Color sea, Color grass, Color sand}) colours = islandColours(land.domain);
    // The card of a touched drawing has the band between the land's name and the drawings (the name grows with large text).
    final double titleBottom =
        _titleTop +
        textBox(landOf(land).label.text, _titleStyle, MediaQuery.textScalerOf(context)).height +
        2 * _titlePadV;
    final double cardTop = titleBottom + _cardGap;
    final double cardBand = _roomTop - _cardGap - cardTop;
    return Scaffold(
      backgroundColor: colours.sea,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _IslandPainter(colours))),
            // The drawings have the room between the name (and the card of a touched drawing) above and the play button and
            // the legend below, and are made as large as that room lets all of them be.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(56, _roomTop, 56, 136),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints room) {
                    final double size = objectSizeFor(objects.length, room.maxWidth, room.maxHeight);
                    return Center(
                      child: SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: _gap,
                          runSpacing: _gap,
                          children: <Widget>[
                            for (int i = 0; i < objects.length; i++)
                              Semantics(
                                label: objects[i].bell
                                    ? '${objects[i].title}. ${He.bellSemantics.text}'
                                    : objects[i].title,
                                button: true,
                                child: GestureDetector(
                                  key: Key('object-${objects[i].skillId}'),
                                  behavior: HitTestBehavior.opaque,
                                  // A bell flag opens its short revisit; any other drawing says what it is.
                                  onTap: () {
                                    final WorldObject o = objects[i];
                                    final Lesson? mission = o.bell && view != null
                                        ? view.missionFor(o.skillId)
                                        : null;
                                    if (mission != null && onMission != null) {
                                      unawaited(_director.stopFor(this));
                                      onMission!(mission);
                                    } else {
                                      _pick(o);
                                    }
                                  },
                                  child: ExcludeSemantics(
                                    child: _OnStone(
                                      first: i == 0,
                                      size: size,
                                      child: WorldObjectView(object: objects[i], size: size),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            PositionedDirectional(
              start: 16,
              top: 8,
              child: PebbleButton(
                key: const Key('land-back'),
                semanticLabel: He.landBackSemantics.text,
                size: 48,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: () => Navigator.of(context).pop(),
                child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
              ),
            ),
            for (final int steps in decorationSteps)
              if (given.contains(Awards.decoration(steps)))
                switch (steps) {
                  10 => PositionedDirectional(
                    start: 24,
                    bottom: 14,
                    child: BoardSvg(
                      'assets/art/decorations/deco_10.svg',
                      key: const Key('island-deco-10'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                  20 => PositionedDirectional(
                    end: 24,
                    top: 64,
                    child: BoardSvg(
                      'assets/art/decorations/deco_20.svg',
                      key: const Key('island-deco-20'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                  _ => PositionedDirectional(
                    end: 24,
                    bottom: 14,
                    child: BoardSvg(
                      'assets/art/decorations/deco_30.svg',
                      key: const Key('island-deco-30'),
                      width: 56,
                      height: 56,
                    ),
                  ),
                },
            // What the touched drawing is: in the band between the land's name and the drawings, so it never covers either.
            if (picked != null && cardBand > 0)
              Positioned(
                left: 16,
                right: 16,
                top: cardTop,
                height: cardBand,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints band) => Align(
                    alignment: Alignment.topCenter,
                    child: ListenableBuilder(
                      listenable: _director,
                      builder: (BuildContext context, Widget? _) {
                        final String? voice = picked.line == null ? null : skillLineVoiceId(picked.skillId);
                        return _ObjectCard(
                          key: const Key('land-object-card'),
                          stage: switch (picked.stage) {
                            GrowthStage.sketch => He.stageSketch.text,
                            GrowthStage.colour => He.stageColour.text,
                            GrowthStage.fruit => He.stageFruit.text,
                          },
                          line: picked.line ?? picked.title,
                          voiced: voice != null,
                          speaking: voice != null && _director.speaking && _director.current == voice,
                          maxWidth: band.maxWidth,
                          maxHeight: band.maxHeight,
                        );
                      },
                    ),
                  ),
                ),
              ),
            // The land's name.
            Positioned(
              top: _titleTop,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  key: const Key('land-title'),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: _titlePadV),
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: softShadow,
                  ),
                  child: Text(landOf(land).label.text, style: _titleStyle),
                ),
              ),
            ),
            // What the drawings mean: practising, knowing, remembering.
            PositionedDirectional(
              start: 16,
              bottom: 12,
              child: Semantics(
                label: He.legendSemantics.text,
                child: ExcludeSemantics(child: _Legend(key: const Key('land-legend'))),
              ),
            ),
            if (onPlay != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PlayPebble(
                        key: const Key('land-play'),
                        semanticLabel: He.landPlaySemantics.text,
                        size: 72,
                        onPressed: onPlay,
                      ),
                      Text(He.landPlayLabel.text, style: AppText.fixed(size: 18, weight: 700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const double _gap = 8;

/// Where the land's name stands and its padding, and where the drawings' room starts (below the name and the card's band).
const double _titleTop = 12;
const double _titlePadV = 6;
const double _roomTop = 146;

/// The space kept between the card of a touched drawing and the name above it or the drawings below it.
const double _cardGap = 4;
final TextStyle _titleStyle = AppText.fixed(size: 24, weight: 700);

/// The size of [text] in [style] at the device's text size, on one line (or wrapped at [maxWidth]).
Size textBox(String text, TextStyle style, TextScaler scaler, {double maxWidth = double.infinity}) {
  final TextPainter p = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.rtl,
    textScaler: scaler,
  )..layout(maxWidth: maxWidth);
  final Size size = p.size;
  p.dispose();
  return size;
}

/// The card of a touched drawing: where it stands (still practised, known, known and remembered) and its line, with the
/// speaker mark when the line is said aloud and a soft gold while it is being said (no flashing, nothing that counts).
/// It fits the band it is given: the stage above the line when both fit, otherwise the two side by side on one row, made
/// smaller only if that row is still too wide (large text on a small phone). So it never covers the name or a drawing.
class _ObjectCard extends StatelessWidget {
  const _ObjectCard({
    super.key,
    required this.stage,
    required this.line,
    required this.voiced,
    required this.speaking,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String stage;
  final String line;
  final bool voiced;
  final bool speaking;
  final double maxWidth;
  final double maxHeight;

  static const double _padH = 18;
  static const double _padV = 6;
  static const double _border = TokenBorder.thin;
  static const double _mark = 28;
  static const double _markGap = 10;
  static final TextStyle _stageStyle = AppText.fixed(size: 18, weight: 700);
  static final TextStyle _lineStyle = AppText.fixed(size: 15, weight: 500);

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double side = voiced ? _mark + _markGap : 0;
    final double textMax = maxWidth - 2 * (_padH + _border) - side;
    final bool stacked =
        textMax > 0 &&
        textBox(stage, _stageStyle, scaler, maxWidth: textMax).height +
                textBox(line, _lineStyle, scaler, maxWidth: textMax).height +
                2 * (_padV + _border) <=
            maxHeight;
    final List<Widget> mark = <Widget>[
      if (voiced) ...<Widget>[const SizedBox(width: _markGap), const SpeakerMark(size: _mark)],
    ];
    final Widget card = AnimatedContainer(
      duration: TokenMotion.dBase,
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
      decoration: BoxDecoration(
        color: speaking ? TokenColors.sparkTint : TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        border: Border.all(color: speaking ? TokenColors.spark : TokenColors.paper, width: _border),
        boxShadow: softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: stacked
            ? <Widget>[
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(stage, textAlign: TextAlign.center, style: _stageStyle),
                      Text(line, textAlign: TextAlign.center, style: _lineStyle),
                    ],
                  ),
                ),
                ...mark,
              ]
            : <Widget>[
                Text(stage, style: _stageStyle),
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(color: TokenColors.cardLip, shape: BoxShape.circle),
                ),
                Text(line, style: _lineStyle),
                ...mark,
              ],
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: stacked ? card : FittedBox(fit: BoxFit.scaleDown, child: card),
    );
  }
}

/// How large each drawing of a land can be: the largest size, from 88 down to 44 points, at which all [count] fit in a
/// room of [width] by [height] points without scrolling (a drawing is 1.2 times as wide and 1.25 times as tall as its size,
/// and stands on a stone). Below 44 the drawings stay that small and the island scrolls.
double objectSizeFor(int count, double width, double height) {
  for (double size = 88; size >= 44; size -= 4) {
    final double w = size * 1.2 + _gap;
    final int perRow = ((width + _gap) / w).floor().clamp(1, 1000);
    final int rows = (count / perRow).ceil();
    if (rows * (size * 1.25 + 12 + _gap) <= height) return size;
  }
  return 44;
}

/// A drawing standing on its stone, with a dotted trail from the one before it (the trail runs on the start side, which is
/// the right in Hebrew). The order is only the order the skills are listed in: nothing here is locked.
class _OnStone extends StatelessWidget {
  const _OnStone({required this.first, required this.child, this.size = 96});

  final bool first;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.bottomCenter,
    children: <Widget>[
      Positioned(
        bottom: -6,
        child: Container(
          width: size * 1.08,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: TokenColors.worldWoodLight,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      if (!first)
        PositionedDirectional(
          start: -size * 0.2,
          bottom: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(color: TokenColors.worldWoodLight, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      child,
    ],
  );
}

/// Three small pictures that say what the drawings on the island mean, left to right in reading order: a faded one is still
/// being practised, a coloured one is known, a coloured one with fruit and a golden star is remembered.
class _Legend extends StatelessWidget {
  const _Legend({super.key});

  WorldObject _sample(GrowthStage stage) =>
      WorldObject(skillId: 'legend', title: '', objectId: 'stair', stage: stage, bell: false);

  Widget _item(GrowthStage stage, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: 56,
        height: 60,
        child: FittedBox(child: WorldObjectView(object: _sample(stage), size: 48)),
      ),
      Text(label, style: AppText.fixed(size: 13, weight: 700)),
    ],
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: TokenColors.paper.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(TokenRadius.xl),
      boxShadow: softShadow,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _item(GrowthStage.sketch, He.legendSketch.text),
        const SizedBox(width: 6),
        _item(GrowthStage.colour, He.legendColour.text),
        const SizedBox(width: 6),
        _item(GrowthStage.fruit, He.legendStar.text),
      ],
    ),
  );
}

class _IslandPainter extends CustomPainter {
  const _IslandPainter(this.colours);

  final ({Color sea, Color grass, Color sand}) colours;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect sand = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.58),
      width: size.width * 0.92,
      height: size.height * 0.78,
    );
    canvas.drawOval(sand, Paint()..color = colours.sand);
    canvas.drawOval(sand.deflate(14), Paint()..color = colours.grass);
  }

  @override
  bool shouldRepaint(_IslandPainter old) => old.colours != colours;
}
