import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/layout.dart';
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
  });

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

  @override
  Widget build(BuildContext context) {
    final bool speakers = _hasSpeakers;
    return Directionality(
      textDirection: direction,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int i, ChoiceOption o) in options.indexed)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Opacity(
                      opacity: answerShown && o.id != correctId ? 0.35 : 1,
                      child: AnswerTile(
                        key: Key('tile-${o.id}'),
                        semanticLabel: o.label ?? '',
                        state: chosenId == o.id
                            ? chosenState
                            : (answerShown && o.id == correctId ? AnswerState.selected : AnswerState.idle),
                        onPressed: () => onChoose(o.id),
                        child: OptionFace(
                          option: o,
                          assets: assets,
                          course: course,
                          tileFont: tileFont,
                          stress: stress,
                        ),
                      ),
                    ),
                    if (litIndex == i)
                      Positioned.fill(
                        left: 6,
                        top: 6,
                        right: 6,
                        bottom: 6,
                        child: const IgnorePointer(
                          child: SkyRing(
                            key: Key('hint-tile-glow'),
                            round: false,
                            radius: TokenRadius.xl + 6,
                          ),
                        ),
                      ),
                  ],
                ),
                if (speakers)
                  SizedBox(
                    height: SpeakerMark.room,
                    child: o.clip == null
                        ? null
                        : Center(
                            child: SpeakerMark(
                              key: Key('speaker-${o.id}'),
                              touch: AppLayout.of(context).touch.minControl,
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
