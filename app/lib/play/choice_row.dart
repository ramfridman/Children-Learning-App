import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/layout.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import 'caption_policy.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'option_faces.dart';
import 'template_session.dart';

// The row of answer tiles of the language templates of L4 (the pause of a story, a button of a command, the gap of a rhyme, the bubble
// of a puppet). It is the tile of LS01 (docs/languages/frame.md section 2.3): a picture, a text in the course's font or a sound
// button, in the course's reading direction, with a speaker under it when the option has a clip of its own to play without answering.

/// What an option shows on its tile.
class OptionFace extends StatelessWidget {
  const OptionFace({
    super.key,
    required this.option,
    required this.assets,
    required this.course,
    required this.tileFont,
    this.stress = true,
  });

  final ChoiceOption option;
  final PackAssets assets;
  final String course;
  final double tileFont;
  final bool stress;

  @override
  Widget build(BuildContext context) {
    if (option.text != null) {
      return OptionTextFace(
        text: withStress(option.text!, show: stress),
        course: course,
        tileFont: tileFont,
        letter: false,
      );
    }
    if (option.sprite != null) {
      return Padding(padding: const EdgeInsets.all(6), child: PackSvg(assets.svg(option.sprite!)));
    }
    if (option.numeral != null) {
      return Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${option.numeral}',
            style: TextStyle(fontSize: tileFont, fontWeight: FontWeight.w800, height: 1),
          ),
        ),
      );
    }
    return const SoundFace();
  }
}

/// The board with the room that a speaker under each tile needs: the tiles stand higher (a speaker is 64 points to touch and must fit
/// above the bottom edge where no hotspot may be), and the stage gives way. A board that has the room is unchanged.
ActivitySpec withSpeakerRoom(ActivitySpec base) {
  const double tile = 96;
  const double margin = 12;
  final double top = math.min(
    base.tilesTop,
    base.boardHeight - TokenTouch.bottomNoHotspot - SpeakerMark.room - margin - tile - margin,
  );
  if (top >= base.tilesTop) return base;
  return base.withStageAndTiles(
    stage: Rect.fromLTWH(
      base.stage.left,
      base.stage.top,
      base.stage.width,
      math.max(0, math.min(base.stage.height, top - 16 - base.stage.top)),
    ),
    tilesLeft: base.tilesLeft,
    tilesTop: top,
    tilesWidth: base.tilesWidth,
  );
}

/// The board of a phone at a question whose options have speakers: the stage keeps its size (the SE's grows to 116 high) and each speaker
/// stands beside its tile, so the picture the question is about is not made a thumbnail (docs/design/languages-l4-layout.md section 4).
/// A tablet keeps [withSpeakerRoom] (the speaker under its tile).
ActivitySpec withSideSpeakers(ActivitySpec base) {
  if (base.boardHeight >= 500) return withSpeakerRoom(base);
  if (base.boardHeight > 380) return base;
  return base.withStageAndTiles(
    stage: const Rect.fromLTWH(16, 86, 270, 116),
    tilesLeft: 0,
    tilesTop: 220,
    tilesWidth: 520,
  );
}

/// The board of the modes that L5-1 adds to LS01 (docs/design/languages-l5-ls01.md section 2): two zones, the **stage zone S** (what the question
/// is about: bins, a stem, a sentence, the item now) and the **answer zone A** (what the child touches or moves). On the phones both are wider
/// than the stage and the tile box of L1, because a text at its reading size needs the room; the frame (controls, trail, bubble, guide and
/// microphone) does not move. The tablets keep their card; A stands centred under it, and [wide] is the zone of the story line, which uses the
/// width of the tablet landscape; [secondRow] makes the stage 12 shorter so that a second row of tiles fits (tap-all of 6, a tray of 6 words).
ActivitySpec withLs01Zones(ActivitySpec base, Band band, {bool wide = false, bool secondRow = false}) {
  final bool bandA = band == Band.a;
  if (base.stageIsCard) {
    final bool landscape = base.boardHeight < 1000;
    // The card is the grown one of [withGrownCard]; a second row of tiles under it makes it shorter (docs/design/m11/min-sizes.md S2, S3).
    return base.withStageAndTiles(
      stage: Rect.fromLTWH(
        base.stage.left,
        base.stage.top,
        base.stage.width,
        secondRow ? (landscape ? 288 : 420) : base.stage.height,
      ),
      tilesLeft: landscape ? (wide ? 24 : 62) : 24,
      tilesTop: secondRow ? (landscape ? 548 : 816) : base.tilesTop,
      tilesWidth: landscape ? (wide ? 942 : 772) : 772,
    );
  }
  if (base.boardHeight > 380) {
    // The phone: S from x 24 (was 71) and 148 high; A under it, to the guide at x 617 and the microphone at 661 (it ends at 605).
    return base.withStageAndTiles(
      stage: const Rect.fromLTWH(24, 96, 377, 148),
      tilesLeft: 24,
      tilesTop: bandA ? 258 : 264,
      tilesWidth: 581,
    );
  }
  // The smallest phone: S 144 high (136 in Band A, whose tiles are taller), A to the microphone at x 521 (it ends at 508).
  return base.withStageAndTiles(
    stage: Rect.fromLTWH(24, 86, 262, bandA ? 136 : 144),
    tilesLeft: 24,
    tilesTop: bandA ? 240 : 250,
    tilesWidth: 484,
  );
}

/// The board for a template that has no tiles under its stage (a story being told, a scene to touch or to drag in): the stage has the whole
/// height under the guide's bubble, down to the edge where no hotspot may be, so that the picture is as large as the board lets it be.
ActivitySpec withTallStage(ActivitySpec base) {
  final double bottom = base.boardHeight - TokenTouch.bottomNoHotspot - 20;
  return base.withStageAndTiles(
    stage: Rect.fromLTWH(base.stage.left, base.stage.top, base.stage.width, bottom - base.stage.top),
    tilesLeft: base.tilesLeft,
    tilesTop: base.tilesTop,
    tilesWidth: base.tilesWidth,
  );
}

/// The board of a Meet screen (docs/design/l7-meet-find.md section 4.1): one big picture and nothing to choose. The picture takes the stage
/// column of a phone from top to bottom (a strip of the words met earlier in the set stands at its end side), and the bubble, the guide, the
/// microphone and the "I said it" tile become one corner on the start side: the tile stands under the bubble. A tablet keeps its card (the
/// portrait's is 120 taller: it holds one picture and nothing else) and has the answer zone under it for the tile. The frame (controls,
/// trail, bubble, guide, microphone) does not move.
ActivitySpec withMeetStage(ActivitySpec base) {
  if (base.stageIsCard) return withBigStage(base);
  if (base.boardHeight > 380) {
    return base.withStageAndTiles(
      stage: const Rect.fromLTWH(24, 96, 377, 260),
      tilesLeft: 413,
      tilesTop: 256,
      tilesWidth: 192,
    );
  }
  return base.withStageAndTiles(
    stage: const Rect.fromLTWH(24, 86, 264, 256),
    tilesLeft: 300,
    tilesTop: 238,
    tilesWidth: 208,
  );
}

/// The board of a template that has the stage to itself or with one row of tiles under it, drawn as big as the board lets it be (docs/design/m11/
/// min-sizes.md 2.3 S1 to S3): a phone's stage is the whole start column down to the edge where no hotspot may be (see [withTallStage]); a tablet's
/// card is 848 wide from the margin (a landscape: 400 tall, or [landscapeHeight]) or 772 by 520 (a portrait: [portraitHeight]), the tiles under it, so that
/// what is drawn in it is not at a phone's size in a sea of room.
ActivitySpec withBigStage(ActivitySpec base, {double landscapeHeight = 400, double portraitHeight = 520}) {
  if (!base.stageIsCard) return withTallStage(base);
  final bool land = base.boardHeight < 1000;
  final double height = land ? landscapeHeight : portraitHeight;
  final double width = land ? 848 : 772;
  return base.withStageAndTiles(
    stage: Rect.fromLTWH(24, base.stage.top, width, height),
    tilesLeft: 24,
    tilesTop: base.stage.top + height + 24 + base.tileSlop - 4,
    tilesWidth: width,
  );
}

/// The board of every lesson on a tablet (docs/design/m11/min-sizes.md C1 and C2, the owner's "tablets grow on every screen"): the card is the
/// big one of [withBigStage], 848 by 400 in a landscape and 772 by 520 in a portrait, with the row of tiles under it, so that a template that
/// asks for nothing else is not drawn at a phone's size in a sea of room. A phone's board is unchanged (a phone's template asks for its own).
ActivitySpec withGrownCard(ActivitySpec base) => base.stageIsCard ? withBigStage(base) : base;

/// The board of a phone at a picture choice whose pictures stand on the stage with no answer tiles (docs/design/l7-meet-find.md section 6.4):
/// the stage takes the whole start column, from x 24 to 401 and down to 349 (the small phone: to 288 and 331), so that two pictures are 166
/// points wide where they were about 95. A tablet's card is unchanged.
ActivitySpec withPictureStage(ActivitySpec base) {
  if (base.stageIsCard) return base;
  return base.withStageAndTiles(
    stage: base.boardHeight > 380
        ? const Rect.fromLTWH(24, 96, 377, 253)
        : const Rect.fromLTWH(24, 86, 264, 245),
    tilesLeft: base.tilesLeft,
    tilesTop: base.tilesTop,
    tilesWidth: base.tilesWidth,
  );
}

/// The board of a template whose picture takes the whole start column while nothing stands under it: a phone's stage is a picture stage (x 24 to 401); the
/// smallest phone's is its own width (16 to 286) made tall, so that the bubble beside it keeps the room it had.
ActivitySpec withWideTallStage(ActivitySpec base) {
  if (base.stageIsCard) return base;
  return base.boardHeight > 380 ? withPictureStage(base) : withTallStage(base);
}

/// The board of a phone whose stage is under [height] (the small phone's is 104, the phone's 128) for a template that needs the room, as
/// the bins to sort into or the two rows of a pattern to copy: the stage grows to [height] and the tiles stand lower by what it takes,
/// as far as the edge where no hotspot may be ([tilesBox] is the height of a tile with its tap margin). A tablet's card and a stage that
/// tall are unchanged.
ActivitySpec withStageAtLeast(ActivitySpec base, double height, {required double tilesBox}) {
  if (base.stageIsCard || base.stage.height >= height) return base;
  final double room = base.boardHeight - TokenTouch.bottomNoHotspot - (base.tilesTop - 12 + tilesBox);
  final double by = math.min(height - base.stage.height, math.max(0, room));
  return base.withStageAndTiles(
    stage: Rect.fromLTWH(base.stage.left, base.stage.top, base.stage.width, base.stage.height + by),
    tilesLeft: base.tilesLeft,
    tilesTop: base.tilesTop + by,
    tilesWidth: base.tilesWidth,
  );
}

/// The board of a tablet in landscape for a template that draws a long row: the card of the stage and the box of the tiles under it
/// reach from the board's margin (24) to where they ended, 872 (the guide stands right of that), instead of from 288, so that the
/// cells of the row are as large as the stage is tall, not 400 points of the board unused. Any other board is unchanged.
ActivitySpec withWideStage(ActivitySpec base) {
  const double margin = 24;
  if (!base.stageIsCard || base.stage.left <= margin) return base;
  return base.withStageAndTiles(
    stage: Rect.fromLTRB(margin, base.stage.top, base.stage.right, base.stage.bottom),
    tilesLeft: margin,
    tilesTop: base.tilesTop,
    tilesWidth: base.stage.right - margin,
  );
}

/// The row of answer tiles of one choice, in the course's direction.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.assets,
    required this.course,
    required this.tileFont,
    required this.direction,
    required this.chosenId,
    required this.chosenState,
    required this.correctId,
    required this.answerShown,
    required this.litIndex,
    required this.onChoose,
    this.onSpeak,
    this.stress = true,
    this.speakerBeside = false,
  });

  /// Each speaker stands on the end side of its tile, on one soft pill with it (a phone at a question), not under it.
  final bool speakerBeside;

  final List<ChoiceOption> options;
  final PackAssets assets;
  final String course;
  final double tileFont;
  final TextDirection direction;
  final String? chosenId;
  final AnswerState chosenState;
  final String correctId;

  /// The help is at its top: the right tile is lit and the others dimmed.
  final bool answerShown;

  /// The tile a hint lights now, or null.
  final int? litIndex;
  final void Function(String id) onChoose;

  /// Plays the clip of an option without answering; with it, every option that has a clip gets a speaker under its tile.
  final void Function(ChoiceOption option)? onSpeak;
  final bool stress;

  bool get _hasSpeakers => onSpeak != null && options.any((ChoiceOption o) => o.clip != null);

  /// One option on a phone: the tile and its speaker on a lilac pill, the speaker at the end side in the course's direction.
  Widget _pill(BuildContext context, int i, ChoiceOption o, double inner) {
    final Widget tile = _tile(context, i, o, slop: 0);
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFFECE3FE), borderRadius: BorderRadius.circular(26)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          tile,
          SizedBox(width: inner),
          SizedBox(
            width: 64,
            height: 64,
            child: o.clip == null
                ? null
                : SpeakerMark(key: Key('speaker-${o.id}'), touch: 64, onTap: () => onSpeak!(o)),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, int i, ChoiceOption o, {double slop = 12}) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Opacity(
        opacity: answerShown && o.id != correctId ? 0.35 : 1,
        child: AnswerTile(
          key: Key('tile-${o.id}'),
          semanticLabel: o.label ?? '',
          slop: slop,
          state: chosenId == o.id
              ? chosenState
              : (answerShown && o.id == correctId ? AnswerState.selected : AnswerState.idle),
          onPressed: () => onChoose(o.id),
          child: OptionFace(option: o, assets: assets, course: course, tileFont: tileFont, stress: stress),
        ),
      ),
      if (litIndex == i)
        Positioned.fill(
          left: 6,
          top: 6,
          right: 6,
          bottom: 6,
          child: const IgnorePointer(
            child: SkyRing(key: Key('hint-tile-glow'), round: false, radius: TokenRadius.xl + 6),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final bool speakers = _hasSpeakers;
    if (speakers && speakerBeside) {
      // Options 15 apart (8 on the smallest phone, whose tile and speaker are 4 apart instead of 6).
      final bool narrow = MediaQuery.sizeOf(context).height < 380;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Directionality(
          textDirection: direction,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final (int i, ChoiceOption o) in options.indexed) ...<Widget>[
                if (i > 0) SizedBox(width: narrow ? 8 : 15),
                _pill(context, i, o, narrow ? 4 : 6),
              ],
            ],
          ),
        ),
      );
    }
    return Directionality(
      textDirection: direction,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int i, ChoiceOption o) in options.indexed)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _tile(context, i, o),
                if (speakers)
                  SizedBox(
                    height: SpeakerMark.room,
                    child: o.clip == null
                        ? null
                        : Center(
                            child: SpeakerMark(
                              key: Key('speaker-${o.id}'),
                              // The room under a tile is 64, the Band A floor of a child control (QA-BA-6): a speaker fills it.
                              touch: math.max(SpeakerMark.room, AppLayout.of(context).touch.minControl),
                              onTap: () => onSpeak!(o),
                            ),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Where the tiles of a language item stand, in the direction of its course (the lands keep the screen's).
TextDirection rowDirectionOf(String course, TextDirection screen) => courseRowDirection(course) ?? screen;
