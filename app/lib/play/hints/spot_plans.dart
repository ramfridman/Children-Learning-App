import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../content/models.dart';
import '../build_pattern_session.dart' show BuildPatternSession;
import 'hint_marks.dart';
import 'right_cell.dart';

// Level 2 of spot the mistake (B-40 part 5, curriculum plan section 5.2): the same row shown another way, by what the row is about.
// A correct number path under a row that counts, brackets under the copies of the unit of a pattern or a program, cubes over the
// numbers of a sentence, a baseline under towers that grow, the colours of the rainbow in order, a sample of what the others have in
// common that goes along a sort. No cell is marked, and the mistake is never drawn: the child compares the two pictures. A row that
// no family draws (the steps of washing, a row of unlike shapes) gets null, and the session plays the walk with the sky bar.
//
// Everything is in the stage's own points; the cells stand where [SpotErrorSession.cellCentres] says.

/// The kinds of row of spot the mistake, by the skill that makes them (curriculum plan section 5.2).
enum SpotFamily { numbers, sentence, pattern, seriation, rainbow, sort }

const Map<String, SpotFamily> _familyOfSkill = <String, SpotFamily>{
  'NUM-A-01': SpotFamily.numbers,
  'NUM-A-02': SpotFamily.numbers,
  'NUM-A-03': SpotFamily.numbers,
  'NUM-A-08': SpotFamily.numbers,
  'NUM-B-03': SpotFamily.numbers,
  'NUM-B-11': SpotFamily.numbers,
  'NUM-B-17': SpotFamily.numbers,
  'MATH-B-03': SpotFamily.sentence,
  'MATH-B-09': SpotFamily.sentence,
  'LOG-A-04': SpotFamily.pattern,
  'LOG-A-07': SpotFamily.pattern,
  'LOG-B-02': SpotFamily.pattern,
  'CS-B-04': SpotFamily.pattern,
  'LOG-B-11': SpotFamily.seriation,
  'COL-B-06': SpotFamily.rainbow,
  'COL-A-02': SpotFamily.sort,
  'COL-A-03': SpotFamily.sort,
  'COL-A-06': SpotFamily.sort,
  'COL-B-04': SpotFamily.sort,
  'LOG-A-01': SpotFamily.sort,
  'LOG-B-06': SpotFamily.sort,
  'SHP-A-02': SpotFamily.sort,
  'SHP-A-03': SpotFamily.sort,
  'SHP-B-01': SpotFamily.sort,
  'SHP-B-03': SpotFamily.sort,
  'SHP-B-04': SpotFamily.sort,
  'SHP-B-08': SpotFamily.sort,
};

/// The colours of the rainbow, in its order.
const List<String> rainbowOrder = <String>['red', 'orange', 'yellow', 'green', 'blue', 'purple'];

/// The plan of level 2 for [a] in a stage of [size], whose [n] cells are centred at [centres] and [side] wide; null when the row has
/// no picture of its own. [svgOf] reads a picture of the pack.
HintPlan? spotAnotherWay(
  SpotErrorActivity a,
  Size size,
  List<Offset> centres,
  double side,
  String Function(String sprite) svgOf,
) {
  final SpotFamily? family = _familyOfSkill[a.skillId];
  if (family == null || centres.isEmpty) return null;
  final _Row row = _Row(a, size, centres, side);
  return switch (family) {
    SpotFamily.numbers => row.path(),
    SpotFamily.sentence => row.cubes(),
    SpotFamily.pattern => row.brackets(),
    SpotFamily.seriation => row.baseline(),
    SpotFamily.rainbow => row.rainbow(),
    SpotFamily.sort => row.sample(svgOf),
  };
}

/// A row of cells in a stage, and the pictures that go with it.
class _Row {
  _Row(this.a, this.size, this.centres, this.side) : k = math.max(0.85, size.height / 128) {
    cells = a.cells;
    n = cells.length;
    pitch = side + 6;
    top = centres.first.dy - side / 2;
    bottom = centres.first.dy + side / 2;
    final String? right = rightCellOf(cells, a.wrong);
    fixed = right == null
        ? null
        : <String>[...cells.sublist(0, a.wrong), right, ...cells.sublist(a.wrong + 1)];
  }

  final SpotErrorActivity a;
  final Size size;
  final List<Offset> centres;
  final double side;
  final double k;
  late final List<String> cells;
  late final int n;
  late final double pitch;
  late final double top;
  late final double bottom;

  /// The row as it would be with its mistake put right (null where the row alone does not tell).
  late final List<String>? fixed;

  static const Duration _step = Duration(milliseconds: 450);

  /// A hint that comes one step at a time and stays: [steps] are the marks after each step.
  HintPlan _growing(List<List<HintMark>> steps, {Duration hold = _step}) =>
      HintPlan(<HintFrame>[for (final List<HintMark> s in steps) HintFrame(s, hold: hold)], rest: steps.last);

  int? _number(String cell) => cell.startsWith('n:') ? int.tryParse(cell.substring(2)) : null;

  /// A row that counts: a correct number path under it, square for cell, a cell at a time (the numbers as the row should read).
  HintPlan? path() {
    final List<String>? row = fixed;
    if (row == null) return null;
    final List<int?> v = <int?>[for (final String c in row) _number(c)];
    if (v.any((int? x) => x == null) || n < 3) return null;
    final int step = v[1]! - v.first!;
    for (int i = 1; i < n; i++) {
      if (v[i]! - v[i - 1]! != step) return null; // only a row that counts by one step has a path
    }
    final double height = math.min(26 * k, size.height - bottom - 8 * k - 4);
    if (height < 16) return null;
    final Rect rect = Rect.fromLTWH(centres.first.dx - pitch / 2, bottom + 8 * k, pitch * n, height);
    return _growing(<List<HintMark>>[
      for (int i = 1; i <= n; i++)
        <HintMark>[PathMark(rect: rect, count: n, upTo: i, from: v.first!, step: step)],
    ]);
  }

  /// A sentence: cubes over each number, as many as it says (rows of five), one number after the other.
  HintPlan? cubes() {
    final List<int> at = <int>[
      for (int i = 0; i < n; i++)
        if (_number(cells[i]) != null) i,
    ];
    if (at.length < 3) return null;
    // As big as the room over the row lets them be: a row of five may be a little wider than its cell (the cells beside a number
    // are signs, with nothing over them), and the tallest pile of rows still fits under the stage's top edge.
    final double room = top - 6 * k;
    final int rows = at.fold(1, (int m, int i) => math.max(m, (_number(cells[i])! / 5).ceil()));
    final double cs = math.min(math.min(13 * k, (side + 18 * k) / 5 - 2), room / rows - 2);
    if (cs < 4 || room < cs) return null;
    final List<List<HintMark>> steps = <List<HintMark>>[];
    final List<HintMark> shown = <HintMark>[];
    for (final int i in at) {
      final int count = _number(cells[i])!;
      final double w = math.min(count, 5) * (cs + 2) - 2;
      for (int j = 0; j < count; j++) {
        shown.add(
          BlockMark(
            Rect.fromLTWH(
              centres[i].dx - w / 2 + (j % 5) * (cs + 2),
              top - 4 * k - cs - (j ~/ 5) * (cs + 2),
              cs,
              cs,
            ),
          ),
        );
      }
      steps.add(List<HintMark>.of(shown));
    }
    return _growing(steps, hold: const Duration(milliseconds: 700));
  }

  /// A pattern or a program: a bracket under each whole copy of the unit that repeats (the row put right is what shows the unit), one
  /// after the other.
  HintPlan? brackets() {
    final List<String>? row = fixed;
    final int? unit = row == null ? null : BuildPatternSession.unitLength(row);
    if (unit == null || unit < 2 || n ~/ unit < 2) return null;
    final List<List<HintMark>> steps = <List<HintMark>>[];
    final List<HintMark> shown = <HintMark>[];
    for (int c = 0; c < n ~/ unit; c++) {
      shown.add(
        BracketMark(
          Offset(centres[c * unit].dx - side / 2 + 2, bottom + 5 * k),
          Offset(centres[c * unit + unit - 1].dx + side / 2 - 2, bottom + 5 * k),
        ),
      );
      steps.add(List<HintMark>.of(shown));
    }
    return _growing(steps, hold: const Duration(milliseconds: 650));
  }

  /// Towers that grow: a dotted floor under the row, so that the heights line up from one start line.
  HintPlan baseline() {
    final List<HintMark> floor = <HintMark>[
      LineMark(
        Offset(centres.first.dx - side / 2, bottom + 3 * k),
        Offset(centres.last.dx + side / 2, bottom + 3 * k),
      ),
    ];
    return HintPlan(<HintFrame>[HintFrame(floor, hold: const Duration(milliseconds: 2400))], rest: floor);
  }

  /// A rainbow: the paint of each place of the rainbow's order under its cell, from the left, one after the other.
  HintPlan? rainbow() {
    if (n != rainbowOrder.length) return null;
    final double d = math.min(30 * k, math.min(side, size.height - bottom - 8 * k - 4));
    if (d < 16) return null;
    return _growing(<List<HintMark>>[
      for (int i = 1; i <= n; i++)
        <HintMark>[
          for (int j = 0; j < i; j++)
            SwatchMark(
              Rect.fromCenter(center: Offset(centres[j].dx, bottom + 8 * k + d / 2), width: d, height: d),
              rainbowOrder[j],
            ),
        ],
    ]);
  }

  // ---- a sort: what the cells but one have in common, held beside each cell in turn ----

  static String? _colourOf(String cell) {
    final String last = cell.split('_').last;
    return hintColours.containsKey(last) ? last : null;
  }

  static const Map<String, GhostKind> _shapes = <String, GhostKind>{
    'circle': GhostKind.circle,
    'square': GhostKind.square,
    'rect': GhostKind.rect,
    'triangle': GhostKind.triangle,
  };

  /// The kind of shape a cell (`asset:shape_square_tilt`) draws, or null.
  static GhostKind? _shapeOf(String cell) {
    final List<String> parts = cell.replaceFirst('asset:', '').split('_');
    return parts.length >= 2 && parts.first == 'shape' ? _shapes[parts[1]] : null;
  }

  /// The sample that belongs beside a cell of a sort, drawn in [at]: the picture all the others are (when they are alike), their
  /// colour or their kind of shape; null when the others have nothing in common that a picture could be.
  HintMark? Function(Rect at)? _sampleOf(String Function(String) svgOf) {
    final List<String> others = <String>[
      for (int i = 0; i < n; i++)
        if (i != a.wrong) cells[i],
    ];
    if (others.toSet().length == 1 && others.first.startsWith('asset:') && others.first != cells[a.wrong]) {
      return (Rect at) => CopyMark(at, svgOf(others.first));
    }
    final Set<String?> colours = <String?>{for (final String c in others) _colourOf(c)};
    if (colours.length == 1 && colours.first != null && colours.first != _colourOf(cells[a.wrong])) {
      return (Rect at) => SwatchMark(at, colours.first!);
    }
    final Set<GhostKind?> shapes = <GhostKind?>{for (final String c in others) _shapeOf(c)};
    if (shapes.length == 1 && shapes.first != null && shapes.first != _shapeOf(cells[a.wrong])) {
      return (Rect at) => GhostMark(at, shapes.first!);
    }
    return null;
  }

  HintPlan? sample(String Function(String) svgOf) {
    final HintMark? Function(Rect)? make = _sampleOf(svgOf);
    // The sample is as big as a child can read on a phone: it stands over the top of each cell, its foot on the cell's white
    // margin (the cell's own picture starts lower), so that a row that fills the stage still leaves it room.
    final double foot = top + math.min(10 * k, side * 0.14);
    final double d = math.min(34 * k, foot - 3);
    if (make == null || d < 18) return null;
    return HintPlan(<HintFrame>[
      for (int i = 0; i < n; i++)
        HintFrame(<HintMark>[
          make(Rect.fromCenter(center: Offset(centres[i].dx, foot - d / 2), width: d, height: d))!,
        ], hold: const Duration(milliseconds: 700)),
    ]);
  }
}
