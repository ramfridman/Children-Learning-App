import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/tokens.g.dart';

// The pictures of a number that `tap_answer` 1.4 draws on its stage (M10, X1): base-ten blocks (`scene.picture.kind` `base_ten`) and the
// hundred chart (`hundred_chart`). The stage draws them, and the hints of the same skills draw them again (a card of blocks, a chart
// with its column shaded), so the places of every block and cell come from one layout, here, and the hint stands on the same places.
//
// Both are read left to right whatever the language: the tens stand left of the ones, the chart runs 1 to 10 along its top row. The digits
// are never on the picture of blocks; the chart writes only the numbers of its lit cells (the question's own numbers).

/// A number as blocks: how many thousands, hundreds, tens and ones.
class BaseTen {
  const BaseTen({
    this.thousands = 0,
    this.hundreds = 0,
    this.tens = 0,
    this.ones = 0,
    this.litRods = 0,
    this.crossedRods = 0,
  });

  /// The blocks of [n] (0 to 9,999): one block for each digit's worth.
  factory BaseTen.of(int n) =>
      BaseTen(thousands: n ~/ 1000 % 10, hundreds: n ~/ 100 % 10, tens: n ~/ 10 % 10, ones: n % 10);

  /// The blocks a stage picture says (`scene.picture` of kind `base_ten`); a field it leaves out is none.
  factory BaseTen.fromScene(Map<String, Object?> picture) => BaseTen(
    thousands: (picture['thousands'] as int?) ?? 0,
    hundreds: (picture['hundreds'] as int?) ?? 0,
    tens: (picture['tens'] as int?) ?? 0,
    ones: (picture['ones'] as int?) ?? 0,
    litRods: (picture['litRods'] as int?) ?? 0,
    crossedRods: (picture['crossedRods'] as int?) ?? 0,
  );

  final int thousands;
  final int hundreds;
  final int tens;
  final int ones;

  /// How many of the tens rods, from the left, are lit (a question about the rod), and how many, from the right, are crossed out (taken
  /// away). Only the stage's picture sets them.
  final int litRods;
  final int crossedRods;

  int get value => thousands * 1000 + hundreds * 100 + tens * 10 + ones;

  /// How many blocks there are in all (the most a picture draws one by one).
  int get blocks => thousands + hundreds + tens + ones;
}

/// Where the blocks of a [BaseTen] stand in a box of [area], left to right: thousands, hundreds, tens, ones. [unit] is one cell's side;
/// a rod is one unit wide and ten tall, a flat is ten by ten, a cube of thousand is ten by ten with its top and side showing, ones
/// stand in columns of three. The whole is centred in the box. All rects are in the box's own points.
class BaseTenLayout {
  /// How wide and how tall the blocks of [n] are, in units (one cube's side): what a box needs, whatever size it is drawn at.
  static Size extentOf(BaseTen n) {
    final int cubeCols = n.ones == 0 ? 0 : math.min(3, n.ones);
    final int cubeRows = (n.ones / 3).ceil();
    final List<double> parts = <double>[
      if (n.thousands > 0) 10 + 3 + (n.thousands - 1) * _thouStep,
      if (n.hundreds > 0) 10 + (n.hundreds - 1) * _flatStep,
      if (n.tens > 0) 1 + (n.tens - 1) * _rodStep,
      if (n.ones > 0) 1 + (cubeCols - 1) * _cubeStep,
    ];
    final double wide =
        parts.fold(0.0, (double s, double w) => s + w) + math.max(0, parts.length - 1) * _groupGap;
    final double tall = n.thousands > 0
        ? 13
        : (n.hundreds > 0 || n.tens > 0 ? 10 : (n.ones > 0 ? 1 + (cubeRows - 1) * _cubeStep : 1));
    return Size(wide, tall);
  }

  // Steps in units: a flat leans on the one before it, a rod has a gap beside it, the groups of blocks are apart, ones stand in threes.
  static const double _flatStep = 2.4, _rodStep = 1.4, _thouStep = 3.2, _groupGap = 1.8, _cubeStep = 1.3;

  factory BaseTenLayout(BaseTen n, Size area, {double maxUnit = 16, double? sharedUnit}) {
    const double flatStep = _flatStep,
        rodStep = _rodStep,
        thouStep = _thouStep,
        groupGap = _groupGap,
        cubeStep = _cubeStep;
    final Size extent = extentOf(n);
    final double wide = extent.width;
    final double tall = extent.height;
    final double fit = math.min(
      maxUnit,
      math.min(area.width / math.max(1, wide), area.height / math.max(1, tall)),
    );
    // A [sharedUnit] is the side of one cube that a set of pictures all draw with; the blocks never go beyond what fits the box.
    final double unit = math.min(fit, sharedUnit ?? fit);
    final Offset origin = Offset((area.width - wide * unit) / 2, (area.height - tall * unit) / 2);
    final double floor = origin.dy + tall * unit;
    final List<Rect> thousands = <Rect>[];
    final List<Rect> hundreds = <Rect>[];
    final List<Rect> tens = <Rect>[];
    final List<Rect> ones = <Rect>[];
    double x = origin.dx;
    if (n.thousands > 0) {
      for (int i = 0; i < n.thousands; i++) {
        thousands.add(Rect.fromLTWH(x + i * thouStep * unit, floor - 13 * unit, 13 * unit, 13 * unit));
      }
      x += (10 + 3 + (n.thousands - 1) * thouStep + groupGap) * unit;
    }
    if (n.hundreds > 0) {
      for (int i = 0; i < n.hundreds; i++) {
        hundreds.add(Rect.fromLTWH(x + i * flatStep * unit, floor - 10 * unit, 10 * unit, 10 * unit));
      }
      x += (10 + (n.hundreds - 1) * flatStep + groupGap) * unit;
    }
    if (n.tens > 0) {
      for (int i = 0; i < n.tens; i++) {
        tens.add(Rect.fromLTWH(x + i * rodStep * unit, floor - 10 * unit, unit, 10 * unit));
      }
      x += (1 + (n.tens - 1) * rodStep + groupGap) * unit;
    }
    if (n.ones > 0) {
      for (int i = 0; i < n.ones; i++) {
        ones.add(
          Rect.fromLTWH(x + (i % 3) * cubeStep * unit, floor - unit - (i ~/ 3) * cubeStep * unit, unit, unit),
        );
      }
    }
    return BaseTenLayout._(unit, thousands, hundreds, tens, ones);
  }

  const BaseTenLayout._(this.unit, this.thousands, this.hundreds, this.tens, this.ones);

  /// The layout [BaseTenPicture] draws in a box of [size] (a bigger unit on a tablet's stage): the stage and the hints call this one.
  factory BaseTenLayout.forBox(BaseTen n, Size size, {double? sharedUnit}) =>
      BaseTenLayout(n, size, maxUnit: size.shortestSide >= 200 ? 28 : 24, sharedUnit: sharedUnit);

  final double unit;
  final List<Rect> thousands;
  final List<Rect> hundreds;
  final List<Rect> tens;
  final List<Rect> ones;

  /// Every block, in reading order (thousands first, ones last).
  List<Rect> get all => <Rect>[...thousands, ...hundreds, ...tens, ...ones];

  /// The box round the tens rods (for a ring on "the tens"), or null when there are none.
  Rect? get tensBox => tens.isEmpty ? null : tens.first.expandToInclude(tens.last);

  /// The box round the ones cubes, or null when there are none.
  Rect? get onesBox =>
      ones.isEmpty ? null : ones.fold<Rect>(ones.first, (Rect r, Rect o) => r.expandToInclude(o));
}

/// The blocks of [n] drawn in the box they are given. [shown] draws only the first of each kind of [layoutOf] (a hint builds the number
/// block by block on the places the whole number has); [hint] draws them in the hint's sky, the stage in the warm colours of the world.
class BaseTenPicture extends StatelessWidget {
  const BaseTenPicture({
    super.key,
    required this.layoutOf,
    this.shown,
    this.hint = false,
    this.places = false,
    this.sharedUnit,
  });

  /// The side of a cube that every picture of one item draws with (the options on a row of tiles), when it is not the box's own best fit.
  final double? sharedUnit;

  /// The number whose places the picture keeps.
  final BaseTen layoutOf;

  /// How much of it is on show now (all of it when null).
  final BaseTen? shown;
  final bool hint;

  /// The blocks that are not on show yet are drawn as empty places (a dashed outline), so that the child sees how many are still to come.
  final bool places;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final Size size = box.biggest;
      final BaseTenLayout l = BaseTenLayout.forBox(layoutOf, size, sharedUnit: sharedUnit);
      return CustomPaint(size: size, painter: _BlocksPainter(l, shown ?? layoutOf, hint, places));
    },
  );
}

class _BlocksPainter extends CustomPainter {
  _BlocksPainter(this.l, this.shown, this.hint, this.places);

  final BaseTenLayout l;
  final BaseTen shown;
  final bool hint;
  final bool places;

  Color get _flat => hint ? TokenColors.sky : TokenColors.lilac;
  Color get _flatEdge => hint ? TokenColors.skyDeep : TokenColors.lilacDeep;
  Color get _rod => hint ? TokenColors.sky : TokenColors.sea;
  Color get _rodEdge => hint ? TokenColors.skyDeep : TokenColors.seaDeep;
  Color get _cube => hint ? TokenColors.sky : TokenColors.spark;
  Color get _cubeEdge => hint ? TokenColors.skyDeep : TokenColors.sparkDeep;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = l.unit;
    final double line = math.max(1, u * 0.12);
    Paint fill(Color c) => Paint()..color = c;
    Paint edge(Color c, [double w = 1]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round;
    RRect r(Rect rect, double radius) => RRect.fromRectAndRadius(rect, Radius.circular(radius));
    for (int i = 0; i < math.min(shown.thousands, l.thousands.length); i++) {
      final Rect t = l.thousands[i];
      final double d = 3 * u;
      final Rect front = Rect.fromLTWH(t.left, t.top + d, 10 * u, 10 * u);
      final Path top = Path()
        ..moveTo(front.left, front.top)
        ..lineTo(front.left + d, front.top - d)
        ..lineTo(front.right + d, front.top - d)
        ..lineTo(front.right, front.top)
        ..close();
      final Path side = Path()
        ..moveTo(front.right, front.top)
        ..lineTo(front.right + d, front.top - d)
        ..lineTo(front.right + d, front.bottom - d)
        ..lineTo(front.right, front.bottom)
        ..close();
      canvas.drawPath(top, fill(Color.lerp(_flat, TokenColors.paper, 0.45)!));
      canvas.drawPath(side, fill(Color.lerp(_flat, _flatEdge, 0.45)!));
      canvas.drawRect(front, fill(_flat));
      canvas.drawPath(top, edge(_flatEdge, line));
      canvas.drawPath(side, edge(_flatEdge, line));
      canvas.drawRect(front, edge(_flatEdge, line));
    }
    for (int i = 0; i < math.min(shown.hundreds, l.hundreds.length); i++) {
      final Rect f = l.hundreds[i];
      canvas.drawRRect(r(f, u * 0.3), fill(_flat));
      if (u >= 3.5) {
        final Paint grid = edge(_flatEdge.withValues(alpha: 0.45), 0.7);
        for (int k = 1; k < 10; k++) {
          canvas.drawLine(Offset(f.left + k * u, f.top), Offset(f.left + k * u, f.bottom), grid);
          canvas.drawLine(Offset(f.left, f.top + k * u), Offset(f.right, f.top + k * u), grid);
        }
      }
      canvas.drawRRect(r(f, u * 0.3), edge(_flatEdge, line));
    }
    for (int i = 0; i < math.min(shown.tens, l.tens.length); i++) {
      final Rect rod = l.tens[i];
      final bool lit = i < shown.litRods;
      final bool crossed = i >= shown.tens - shown.crossedRods;
      if (lit) {
        // A lit rod: the one the question is about, in a wide golden glow with a golden body and a dark golden edge.
        canvas.drawRRect(r(rod.inflate(u * 0.9), u * 0.9), fill(TokenColors.spark.withValues(alpha: 0.35)));
        canvas.drawRRect(r(rod.inflate(u * 0.5), u * 0.6), fill(TokenColors.spark.withValues(alpha: 0.75)));
      }
      canvas.drawRRect(
        r(rod, u * 0.25),
        fill(lit ? TokenColors.spark : (crossed ? _rod.withValues(alpha: 0.35) : _rod)),
      );
      if (u >= 3.5) {
        final Paint seg = edge((lit ? TokenColors.sparkDeep : _rodEdge).withValues(alpha: 0.6), 0.7);
        for (int k = 1; k < 10; k++) {
          canvas.drawLine(Offset(rod.left, rod.top + k * u), Offset(rod.right, rod.top + k * u), seg);
        }
      }
      canvas.drawRRect(
        r(rod, u * 0.25),
        lit ? edge(TokenColors.sparkDeep, math.max(2, u * 0.3)) : edge(_rodEdge, line),
      );
      if (crossed) {
        // Taken away: a cross over the rod, in the ink of the page.
        final Paint cross = edge(TokenColors.ink, math.max(1.5, u * 0.22))..strokeCap = StrokeCap.round;
        final Rect x = Rect.fromCenter(center: rod.center, width: u * 2.2, height: u * 2.2);
        canvas.drawLine(x.topLeft, x.bottomRight, cross);
        canvas.drawLine(x.topRight, x.bottomLeft, cross);
      }
    }
    for (int i = 0; i < math.min(shown.ones, l.ones.length); i++) {
      final Rect c = l.ones[i];
      canvas.drawRRect(r(c, u * 0.25), fill(_cube));
      canvas.drawRRect(r(c, u * 0.25), edge(_cubeEdge, line));
    }
    if (places) {
      // What is still to come: an empty place of each kind (a faint outline, the same size).
      final Paint ghost = edge(TokenColors.skyDeep.withValues(alpha: 0.7), math.max(1, u * 0.12));
      for (final Rect t in l.thousands.skip(shown.thousands)) {
        canvas.drawRect(Rect.fromLTWH(t.left, t.top + 3 * u, 10 * u, 10 * u), ghost);
      }
      for (final Rect f in l.hundreds.skip(shown.hundreds)) {
        canvas.drawRRect(r(f, u * 0.3), ghost);
      }
      for (final Rect rod in l.tens.skip(shown.tens)) {
        canvas.drawRRect(r(rod, u * 0.25), ghost);
      }
      for (final Rect c in l.ones.skip(shown.ones)) {
        canvas.drawRRect(r(c, u * 0.25), ghost);
      }
    }
  }

  @override
  bool shouldRepaint(_BlocksPainter old) =>
      old.l.unit != l.unit ||
      old.shown.value != shown.value ||
      old.shown.litRods != shown.litRods ||
      old.shown.crossedRods != shown.crossedRods ||
      old.hint != hint ||
      old.places != places;
}

// ---- the hundred chart ----

/// What a chart draws: the rows of it that are shown (counted from 0 for the row of 1 to 10), the numbers of the cells that are lit
/// (each with its number written in it), those that are blank (the empty places a number is to be found for), and a column that is
/// shaded (a hint: the rod laid down it), counted from 0 for the column of 1, 11, 21 and so on.
class ChartSpec {
  const ChartSpec({
    required this.firstRow,
    required this.lastRow,
    this.lit = const <int>{},
    this.blank = const <int>{},
    this.shadeColumn,
    this.shadeRow,
  });

  /// The window of a stage picture (`scene.picture` of kind `hundred_chart`). The chart is ten cells wide; on a small board a full ten
  /// rows would make cells of ten points that hold no number a child can read, so the stage shows the rows the question stands in and
  /// one more above and below (at most six); a question that spans more rows shows the whole chart.
  factory ChartSpec.fromScene(Map<String, Object?> picture) => ChartSpec.around(
    <int>{...?(picture['lit'] as List<Object?>?)?.cast<int>()},
    <int>{...?(picture['blank'] as List<Object?>?)?.cast<int>()},
  );

  factory ChartSpec.around(Set<int> lit, Set<int> blank, {bool shadeColumn = false}) {
    final List<int> rows = <int>[
      for (final int n in <int>{...lit, ...blank}) (n - 1) ~/ 10,
    ];
    int first = 0, last = 9;
    if (rows.isNotEmpty) {
      first = math.max(0, rows.reduce(math.min) - 1);
      last = math.min(9, rows.reduce(math.max) + 1);
      if (last - first + 1 > 6) {
        first = 0;
        last = 9;
      }
    }
    final int? column = shadeColumn && lit.isNotEmpty ? (lit.first - 1) % 10 : null;
    return ChartSpec(firstRow: first, lastRow: last, lit: lit, blank: blank, shadeColumn: column);
  }

  final int firstRow;
  final int lastRow;
  final Set<int> lit;
  final Set<int> blank;
  final int? shadeColumn;

  /// A row that is shaded (a hint), counted from 0 for the row of 1 to 10.
  final int? shadeRow;

  int get rows => lastRow - firstRow + 1;

  /// The same window with the column or the row that joins its lit cells to the empty cell [target] shaded: the column when a lit cell
  /// stands in the target's, else the row of the first lit cell. A hint's ten-rod laid down the column, or the row that is counted along.
  ChartSpec shaded(int target) {
    final bool sameColumn = lit.any((int n) => (n - 1) % 10 == (target - 1) % 10);
    return ChartSpec(
      firstRow: firstRow,
      lastRow: lastRow,
      lit: lit,
      blank: blank,
      shadeColumn: sameColumn ? (target - 1) % 10 : null,
      shadeRow: sameColumn || lit.isEmpty ? null : (lit.first - 1) ~/ 10,
    );
  }

  /// The same window with cell [n] lit as well (a number found).
  ChartSpec withLit(int n) => ChartSpec(
    firstRow: firstRow,
    lastRow: lastRow,
    lit: <int>{...lit, n},
    blank: blank.difference(<int>{n}),
    shadeColumn: shadeColumn,
    shadeRow: shadeRow,
  );

  /// The same window with the blank cells lit (the number found).
  ChartSpec withBlankFilled() => ChartSpec(
    firstRow: firstRow,
    lastRow: lastRow,
    lit: <int>{...lit, ...blank},
    shadeColumn: shadeColumn,
    shadeRow: shadeRow,
  );
}

/// Where the cells of a chart stand in a box of [area]: ten cells wide, [ChartSpec.rows] tall, as large as the box lets them be (squares
/// up to [maxCell]), centred. Rects are in the box's own points.
class ChartLayout {
  ChartLayout(this.spec, Size area, {double maxCell = 44}) {
    cell = math.min(maxCell, math.min(area.width / 10, area.height / spec.rows));
    origin = Offset((area.width - cell * 10) / 2, (area.height - cell * spec.rows) / 2);
  }

  /// The layout [HundredChartPicture] draws in a box of [size]: the stage and the hints call this one.
  factory ChartLayout.forBox(ChartSpec spec, Size size) =>
      ChartLayout(spec, size, maxCell: size.shortestSide >= 200 ? 46 : 40);

  final ChartSpec spec;
  late final double cell;
  late final Offset origin;

  /// The rect of the cell of number [n] (1 to 100), or null when its row is not in the window.
  Rect? cellOf(int n) {
    final int row = (n - 1) ~/ 10;
    if (row < spec.firstRow || row > spec.lastRow) return null;
    return Rect.fromLTWH(
      origin.dx + (n - 1) % 10 * cell,
      origin.dy + (row - spec.firstRow) * cell,
      cell,
      cell,
    );
  }

  /// The cells of column [c] (from 0) that the window shows, top to bottom.
  List<Rect> column(int c) => <Rect>[
    for (int row = spec.firstRow; row <= spec.lastRow; row++) cellOf(row * 10 + c + 1)!,
  ];

  Rect get box => Rect.fromLTWH(origin.dx, origin.dy, cell * 10, cell * spec.rows);
}

/// The size of the number (and of the question mark) in a chart cell of [cell] points: 0.66 of it, 0.46 for a hundred. A cell of the
/// small phone's stage is 19 to 27 points (five rows or four), so a two-digit number is 12.7 to 17.8 points there: never under 12
/// (QA-C1b-4).
double chartNumberSize(double cell, int n) => cell * (n >= 100 ? 0.46 : 0.66);

/// A chart drawn by [ChartLayout]: plain squares, the lit ones golden with their number, the blank ones dashed with a question mark.
class HundredChartPicture extends StatelessWidget {
  const HundredChartPicture({super.key, required this.spec, this.hint = false});

  final ChartSpec spec;
  final bool hint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final Size size = box.biggest;
      final ChartLayout l = ChartLayout.forBox(spec, size);
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: _ChartPainter(l, hint))),
            for (final int n in <int>[...spec.lit, ...spec.blank])
              if (l.cellOf(n) case final Rect c)
                Positioned.fromRect(
                  rect: c,
                  child: Center(
                    child: Text(
                      spec.lit.contains(n) ? '$n' : '?',
                      key: Key(spec.lit.contains(n) ? 'chart-lit-$n' : 'chart-blank-$n'),
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      softWrap: false,
                      style: AppText.fixed(size: chartNumberSize(c.height, n), weight: 800, lineHeight: 1),
                    ),
                  ),
                ),
          ],
        ),
      );
    },
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.l, this.hint);

  final ChartLayout l;
  final bool hint;

  @override
  void paint(Canvas canvas, Size size) {
    final double c = l.cell;
    final Paint hair = Paint()
      ..color = TokenColors.cardLip
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Paint ink = Paint()
      ..color = TokenColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(l.box.inflate(1), Radius.circular(math.max(3, c * 0.12))),
      Paint()..color = TokenColors.paper,
    );
    if (l.spec.shadeColumn != null) {
      for (final Rect r in l.column(l.spec.shadeColumn!)) {
        canvas.drawRect(r, Paint()..color = TokenColors.sky.withValues(alpha: 0.4));
      }
    }
    final int? shadeRow = l.spec.shadeRow;
    if (shadeRow != null && shadeRow >= l.spec.firstRow && shadeRow <= l.spec.lastRow) {
      for (int col = 0; col < 10; col++) {
        canvas.drawRect(
          l.cellOf(shadeRow * 10 + col + 1)!,
          Paint()..color = TokenColors.sky.withValues(alpha: 0.4),
        );
      }
    }
    for (int row = l.spec.firstRow; row <= l.spec.lastRow; row++) {
      for (int col = 0; col < 10; col++) {
        final int n = row * 10 + col + 1;
        final Rect r = l.cellOf(n)!;
        if (l.spec.lit.contains(n)) {
          canvas.drawRect(r.deflate(1), Paint()..color = hint ? TokenColors.sparkTint : TokenColors.spark);
        }
        canvas.drawRect(r, hair);
      }
    }
    for (final int n in l.spec.blank) {
      final Rect? r = l.cellOf(n);
      if (r == null) continue;
      final Rect d = r.deflate(math.max(2, c * 0.1));
      // A dashed outline: the place a number is to be found for.
      final Path path = Path()..addRRect(RRect.fromRectAndRadius(d, Radius.circular(c * 0.14)));
      for (final PathMetric m in path.computeMetrics()) {
        for (double at = 0; at < m.length; at += 8) {
          canvas.drawPath(m.extractPath(at, math.min(at + 4, m.length)), ink);
        }
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(l.box, Radius.circular(math.max(3, c * 0.12))),
      Paint()
        ..color = TokenColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.l.spec != l.spec || old.l.cell != l.cell || old.hint != hint;
}
