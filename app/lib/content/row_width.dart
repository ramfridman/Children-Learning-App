// How wide the cells of a `tap_answer` row are, in em (the font size of its numbers and signs). The stage lays a row out by these widths
// (`TapGeometry.rowLayoutOf`) and the validator refuses a row too wide for a small phone, so the two agree by sharing this file. The
// figures are Heebo's: a digit is 0.58 em wide (all alike), a sign 0.58 em (a colon 0.3, a bracket 0.35), with a little room round each.

/// The width of one cell of a row, in em: a number (`n:12`), a sign (`op:+`), the gap to fill (`?`) or a picture (`asset:...`).
double rowCellEm(String cell) {
  if (cell.startsWith('n:')) return (cell.length - 2) * 0.6 + 0.4;
  if (cell == 'op:(' || cell == 'op:)') return 0.6;
  if (cell.startsWith('op:')) return 1.0;
  return 1.2;
}

/// The width of a whole row, in em.
double rowEm(List<String> cells) => cells.fold<double>(0, (double sum, String c) => sum + rowCellEm(c));

/// The widest row a small phone's stage (270 points, less the room at both ends) can show with numbers of 13 points: wider rows are
/// refused, so a number is never drawn too small to read. (Eleven cells with two numbers of five digits are about 17.)
const double maxRowEm = 18;
