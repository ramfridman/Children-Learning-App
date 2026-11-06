import 'package:flutter/material.dart';

import '../design/course_text.dart';
import '../engine/course.dart';
import 'ls01_metrics.dart' show lineHeightFor;
import '../design/tokens.g.dart';
import '../strings/he.dart';

// The faces an answer of a language course can have besides a picture (docs/languages/frame.md, LS01): a text in the course's
// font and direction, a sound button with nothing on it but its sound, a speaker that plays a tile's own clip without
// answering, and the word that appears under a picture once the answer is accepted. The tile itself is `AnswerTile`.

/// The text of a tile, in its course's font and direction, as large as the tile lets it be: in a letter item ([letter]) the tile font
/// in bold, in a word item a little over half of it in Medium, scaled down to fit the width (a long word never wraps and never
/// overflows).
class OptionTextFace extends StatelessWidget {
  const OptionTextFace({
    super.key,
    required this.text,
    required this.course,
    required this.tileFont,
    required this.letter,
    this.readingSize,
  });

  final String text;
  final String course;

  /// The size the text is read at, from the band, the course and the board (docs/design/languages-l5-ls01.md section 3.2). When it is given
  /// the text is drawn at it; the scale-down below stays only as the last safety net, for a text the fit test would have refused.
  final double? readingSize;

  /// The numeral size of the board's tiles (`ActivitySpec.tileFont`).
  final double tileFont;

  /// The item is a letter item (`TapAnswerActivity.letterFace`: the item says so; the text never decides).
  final bool letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: CourseText(
            text,
            course: course,
            size: readingSize ?? (letter ? tileFont : tileFont * 0.55),
            bold: letter,
            lineHeight: readingSize == null ? null : lineHeightFor(text, hebrew: !_latinCourse(course)),
          ),
        ),
      ),
    );
  }
}

bool _latinCourse(String course) => course == Course.eng || course == Course.rus;

/// A sound button's face: a speaker and nothing else. A sound card of a sort that has not been played yet ([heard] false) shows the
/// speaker without its waves, so that the child can tell which cards are still unknown (docs/design/languages-l5-ls01.md section 6).
class SoundFace extends StatelessWidget {
  const SoundFace({super.key, this.heard = true});

  final bool heard;

  @override
  Widget build(BuildContext context) => Icon(
    heard ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
    key: const Key('sound-face'),
    size: 52,
    color: TokenColors.ink,
  );
}

/// A speaker under a text tile: a tap plays the tile's own clip and does not answer. Its disc is 44 points; its touch area is
/// [touch] square, the engineering floor of a child control in the band (64 in Band A, 56 in Bands B and C), and it lies wholly
/// outside the tile and its tap margin, so that it takes nothing from the tile's own touch area and a miss lands on nothing.
class SpeakerMark extends StatelessWidget {
  const SpeakerMark({super.key, required this.onTap, required this.touch});

  static const double disc = 44;

  /// The room under a tile that a speaker has, whatever the band (the larger of the two floors).
  static const double room = 64;

  final VoidCallback onTap;
  final double touch;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: He.optionSoundSemantics.text,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: touch,
        height: touch,
        child: Center(
          child: Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              color: TokenColors.skyTint,
              shape: BoxShape.circle,
              border: Border.all(color: TokenColors.hairline, width: TokenBorder.thin),
            ),
            child: const Icon(Icons.volume_up_rounded, size: 26, color: TokenColors.ink),
          ),
        ),
      ),
    ),
  );
}

/// The word under a picture after the answer (LS01 g): in the course's font, nothing asked of the child, nothing scored.
class RevealCaption extends StatelessWidget {
  const RevealCaption({super.key, required this.text, required this.course, required this.size});

  final String text;
  final String course;
  final double size;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: CourseText(text, course: course, size: size, maxLines: 1),
  );
}
