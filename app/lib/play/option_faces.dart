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

/// Whether an item's options are letters: every one of them is a single letter (or a digraph). The face of a tile follows the item,
/// never its own text, so that the options of one item are all set alike: a word of two letters beside longer words is a word,
/// and the child's own short name among other names does not stand out by its look.
bool isLetterItem(Iterable<String> texts) => texts.isNotEmpty && texts.every(isSingleLetter);

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
  });

  final String text;
  final String course;

  /// The numeral size of the board's tiles (`ActivitySpec.tileFont`).
  final double tileFont;

  /// The item is a letter item (see [isLetterItem]).
  final bool letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
