import '../design/token_types.dart' show Band;

// What a Meet screen shows of the word it teaches (docs/design/l7-meet-find.md section 3.2). The curriculum-expert ruled on 2026-11-12 (C1)
// that D1 of docs/languages/band-a-build.md 7.2 (no target text on a Band A skill) gives way here: a child whose letters gate is open is
// decoding that script, so the word may be written under the bubble's line. The written word is a chip, never on the picture, and it comes
// after the child has heard the word and its meaning, so it never turns the screen into a reading test.

/// Whether a Meet screen prints its word in the chip under the bubble's line, from the third beat on.
///
/// [look] is the child's presentation band in the course (A for 3 to 4, B for 5 to 6, C for 7 to 8): look A never shows text. [lettersOpen] is
/// the letters gate of the course for this child (by level at any age, by age, or "letters together with words"). The chip stands under
/// the speaker when the captions are hidden, so the captions setting does not change the answer.
bool meetShowsWord({required Band look, required bool lettersOpen}) {
  if (look == Band.a) return false;
  return lettersOpen;
}
