import 'package:flutter/material.dart';

import '../design/course_text.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';

// The faces an answer of a language course can have besides a picture (docs/languages/frame.md, LS01): a text in the course's
// font and direction, a sound button with nothing on it but its sound, a speaker that plays a tile's own clip without
// answering, and the word that appears under a picture once the answer is accepted. The tile itself is `AnswerTile`.

/// Whether [text] is one letter (or a digraph, or a vowel sign on one): such a tile is square and shows the letter large and
/// bold. Combining marks (a stress mark, nikud) are not letters.
bool isSingleLetter(String text) {
  int letters = 0;
  for (final int r in text.runes) {
    final bool mark = (r >= 0x0300 && r <= 0x036F) || (r >= 0x05B0 && r <= 0x05C7);
    if (!mark) letters++;
  }
  return letters <= 2;
}

/// The text of a tile, in its course's font and direction, as large as the tile lets it be: a letter at the tile font in bold, a
/// word a little over half of it in Medium, scaled down to fit the width (a long word never wraps and never overflows).
class OptionTextFace extends StatelessWidget {
  const OptionTextFace({
    super.key,
    required this.text,
    required this.course,
    required this.tileFont,
    this.roomBelow = 0,
  });

  final String text;
  final String course;

  /// The numeral size of the board's tiles (`ActivitySpec.tileFont`).
  final double tileFont;

  /// Room kept free at the bottom of the tile for a speaker.
  final double roomBelow;

  @override
  Widget build(BuildContext context) {
    final bool letter = isSingleLetter(text);
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, roomBelow),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: CourseText(text, course: course, size: letter ? tileFont : tileFont * 0.55, bold: letter),
        ),
      ),
    );
  }
}

/// A sound button's face: a speaker and nothing else.
class SoundFace extends StatelessWidget {
  const SoundFace({super.key});

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.volume_up_rounded, key: Key('sound-face'), size: 52, color: TokenColors.ink);
}

/// A small speaker on a text tile: a tap plays the tile's own clip and does not answer. Its disc is 36 points, its touch area 48.
class SpeakerMark extends StatelessWidget {
  const SpeakerMark({super.key, required this.onTap});

  static const double disc = 36;
  static const double touch = 48;

  final VoidCallback onTap;

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
            child: const Icon(Icons.volume_up_rounded, size: 22, color: TokenColors.ink),
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
