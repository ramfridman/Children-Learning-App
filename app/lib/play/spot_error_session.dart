import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import 'choice_row.dart' show withTallStage;
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/right_cell.dart';
import 'hints/spot_plans.dart';
import 'math_signs.dart';
import 'size_scale.dart';
import 'stage_picture.dart';
import 'template_session.dart';

/// The spot-the-mistake template (T21): a friend made a row (a pattern, a count, a program, a sum) and one cell of it is wrong.
/// The child touches the mistake. A wrong touch is a gentle "not yet"; after three only the mistake is taken, and the help rings
/// it, at the end of the guide's walk along the row. The row is read from the left, whatever the language.
class SpotErrorSession extends TemplateSession {
  SpotErrorSession(super.controller, this.activity);

  final SpotErrorActivity activity;

  int? wrongCell;

  /// The cell the help has picked out: the mistake, at the end of the worked example and afterwards (never before).
  int? hintCell;

  /// Hint 1 and 2: the cell the light is on now (none when it has finished), the cells it has been to, and, for hint 2, how far
  /// the sky bar under the row has grown (it points the way along the row, and picks out no cell).
  int? lit;
  final Set<int> visited = <int>{};
  int? barTo;
  int _run = 0;

  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The pointing hand of the worked example (level 3), and the stage's size it is placed by.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;

  /// The look of the size pictures of the row, and their aspect (under 1 for towers), which sets the height of its cells.
  late final SizeLook? look = lookOf(activity);
  late final double aspect = look != null && look!.tall ? look!.aspect : 1;

  /// The least a cell is: the token `touch.minControl` of band A (64: a child of 3 to 5 is wide and unsure with a finger) in the
  /// logic land, whose sweep this is; none elsewhere, where the picture's own least (see [linesOf]) rules until the land's own sweep.
  late final double minCell = activity.band == 'A' && activity.domain == 'logic'
      ? TokenTouch.band[Band.a]!.minControl
      : 0;

  /// The row holds numbers or signs (a number sentence): it stands in one line, its cells as wide as the stage allows, however many.
  late final bool textRow = activity.cells.any((String c) => c.startsWith('n:') || c.startsWith('op:'));

  /// The room a cell takes round its picture: the border (3 each side) and the margin inside it (5 each side).
  static const double _frame = 16;

  /// The space between two cells, and the most that a row leaves between two lines of cells for the guide's card.
  static const double _gap = 6;
  static const double _lineGapMax = 44;

  /// How many lines the [n] cells of a stage of [size] stand in: one, unless its picture would be smaller than the token
  /// `stagePictureMin` (the 8 cells of a pattern on a phone), and then two. The picture is what the child reads, so the cell is
  /// made as large as the stage's width allows before the row is cut.
  ///
  /// A cell is also never smaller than [minCell], the least a control may be (the token `touch.minControl` of band A, 64): four cells
  /// on the small phone's stage of 270 are 57 in one line, and stand in two of two. A row of numbers and signs ([text]) is always one line.
  static int linesOf(Size size, int n, {double minCell = 0, bool text = false}) {
    if (n < 2 || text) return 1;
    final double one = math.min(size.height - 16, (size.width - 16) / n - _gap);
    return one - _frame >= minPictureOf(size) && one >= minCell ? 1 : 2;
  }

  /// How many cells stand on one line, the first lines full.
  static int _perLine(Size size, int n, double minCell, bool text) =>
      (n / linesOf(size, n, minCell: minCell, text: text)).ceil();

  /// The side of a cell of a row of [n] in a stage of [size].
  static double cellSide(Size size, int n, {double minCell = 0, bool text = false}) {
    final int lines = linesOf(size, n, minCell: minCell, text: text);
    final double fit = math.min(
      (size.height - 10) / lines - _gap,
      (size.width - 16) / _perLine(size, n, minCell, text) - _gap,
    );
    // Two lines are given a limit, so that the room between them holds what the hints draw there (a path, a paint, a sample).
    return lines == 1 ? fit : math.min(fit, 1.8 * minPictureOf(size));
  }

  /// The height of a cell: its side, or, for a row of tall pictures (towers, of [aspect] width over height under 1), as tall as the
  /// stage leaves, so that the picture is as large as its width allows and its cubes can be counted.
  static double cellHeight(Size size, int n, {double aspect = 1, double minCell = 0, bool text = false}) {
    final double side = cellSide(size, n, minCell: minCell, text: text);
    if (aspect >= 1) return side;
    final double fit = (size.height - 10) / linesOf(size, n, minCell: minCell, text: text) - _gap;
    return math.min(fit, (side - _frame) / aspect + _frame);
  }

  /// The look of the size pictures of the row (towers, balls of three sizes), cut to one part of their box; null for any other row.
  static SizeLook? lookOf(SpotErrorActivity a) => sizeLookOf(<String>[
    for (final String c in a.cells)
      if (c.startsWith('asset:')) c,
  ], a.assets.svg);

  /// Where the cells of a row of [n] stand in a stage of [size], left to right and line by line from the top: the same numbers the
  /// stage draws with. Every line starts at the same place, so the lines read as one row cut in two; the room that two lines leave
  /// over is shared out between them (a little, for the guide's card) and the stage's top and bottom.
  static List<Offset> cellCentres(
    Size size,
    int n, {
    double aspect = 1,
    double minCell = 0,
    bool text = false,
  }) {
    final double side = cellSide(size, n, minCell: minCell, text: text);
    final double height = cellHeight(size, n, aspect: aspect, minCell: minCell, text: text);
    final int lines = linesOf(size, n, minCell: minCell, text: text);
    final int per = _perLine(size, n, minCell, text);
    final double pitch = side + _gap;
    final double pitchY = height + _gap;
    final double lineGap = lines == 1
        ? 0
        : ((size.height - lines * pitchY) / (lines + 1)).clamp(0, _lineGapMax);
    final double block = lines * pitchY + (lines - 1) * lineGap;
    return <Offset>[
      for (int i = 0; i < n; i++)
        Offset(
          (size.width - per * pitch) / 2 + pitch * (i % per + 0.5),
          (size.height - block) / 2 + (pitchY + lineGap) * (i ~/ per) + pitchY / 2,
        ),
    ];
  }

  /// A row that stands in two lines wants a stage as tall as the board lets it be (the phones: the stage's own 104 or 128 points
  /// are too low for two lines of cells that a child can read); the tablets' stage is a card with room already.
  @override
  ActivitySpec layoutFor(ActivitySpec base) =>
      !base.stageIsCard &&
          linesOf(base.stage.size, activity.cells.length, minCell: minCell, text: textRow) > 1
      ? withTallStage(base)
      : base;

  Future<void> choose(int i) async {
    if (_busy || ring == AnswerState.correct) return;
    _hint.clear();
    if (controller.guided && i != activity.wrong) {
      if (controller.answerShown) hintCell = activity.wrong;
      notify();
      return;
    }
    _busy = true;
    final bool right = i == activity.wrong;
    await controller.submitPlacement(
      right: right,
      tag: right ? '' : (activity.wrongTag ?? ''),
      response: '$i',
    );
    if (disposed) return;
    if (right) {
      ring = AnswerState.correct;
      hintCell = null;
      notify();
      later(praise, controller.next);
      return;
    }
    wrongCell = i;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      wrongCell = null;
      ring = AnswerState.idle;
      _busy = false;
      if (controller.answerShown) hintCell = activity.wrong;
      notify();
    });
  }

  @override
  void onReset() {
    wrongCell = null;
    hintCell = null;
    _clearWalk();
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintCell = null;
    _clearWalk();
    notify();
  }

  void _clearWalk() {
    _run++;
    _hint.clear();
    lit = null;
    barTo = null;
    visited.clear();
  }

  @override
  void onHint() {
    if (_busy && !controller.guided) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.walkTheRow:
        _walk(to: activity.cells.length - 1, bar: false);
      case HintPicture.anotherWay:
        _anotherWay();
      default:
        _walk(to: activity.wrong, bar: false, stopOnWrong: true);
    }
  }

  /// Hint 2: the row another way, by what it is about (a path of numbers under a count, brackets under a pattern, cubes over a sentence,
  /// a sample beside each cell of a sort); a row that has no such picture gets the light going along it with the sky bar under it. No
  /// cell is picked out.
  void _anotherWay() {
    _clearWalk();
    hintCell = null;
    final HintPlan? plan = _size.isEmpty
        ? null
        : spotAnotherWay(
            activity,
            _size,
            cellCentres(_size, activity.cells.length, aspect: aspect, minCell: minCell, text: textRow),
            cellSide(_size, activity.cells.length, minCell: minCell, text: textRow),
            cellHeight(_size, activity.cells.length, aspect: aspect, minCell: minCell, text: textRow),
            (String sprite) => activity.assets.svg(sprite),
          );
    if (plan == null) {
      _walk(to: activity.cells.length - 1, bar: true);
      return;
    }
    _hint.play(plan);
    notify();
  }

  /// The light goes along the row from the left, one cell at a time, as far as [to]. With [stopOnWrong] (the worked example) it
  /// stops there and the cell is picked out: that is the last step, and then the child's turn comes back.
  void _walk({required int to, required bool bar, bool stopOnWrong = false}) {
    _clearWalk();
    hintCell = null;
    if (stopOnWrong && !_size.isEmpty) {
      // The hand reads the row from the left with the light, and stops on the mistake where the light stops.
      final List<Offset> at = cellCentres(
        _size,
        activity.cells.length,
        aspect: aspect,
        minCell: minCell,
        text: textRow,
      );
      _hint.play(
        HintPlan(<HintFrame>[
          for (int i = 0; i <= to; i++)
            HintFrame(<HintMark>[HandMark(at[i], press: true)], hold: const Duration(milliseconds: 700)),
        ], rest: _rightOne(at[to])),
      );
    }
    final int run = _run;
    const int step = 700;
    for (int i = 0; i <= to; i++) {
      later(Duration(milliseconds: step * i), () {
        if (run != _run) return;
        lit = i;
        visited.add(i);
        if (bar) barTo = i;
        notify();
      });
    }
    later(Duration(milliseconds: step * (to + 1)), () {
      if (run != _run) return;
      lit = null;
      if (stopOnWrong) {
        hintCell = activity.wrong;
        visited.clear();
      }
      notify();
      if (stopOnWrong) controller.demoDone();
    });
    notify();
  }

  /// The sky card with what the mistake should have been, above the cell [mistake] where the hand stopped; it stays for the child
  /// to compare (nothing when the row alone does not tell). It lies over the top of the cell a little where the row leaves no room.
  List<HintMark> _rightOne(Offset mistake) {
    final String? right = rightCellOf(activity.cells, activity.wrong);
    if (right == null) return const <HintMark>[];
    final double k = hintScale(_size);
    final double height = cellHeight(
      _size,
      activity.cells.length,
      aspect: aspect,
      minCell: minCell,
      text: textRow,
    );
    // In a row of two lines the card stands in the room between them, over the cell above only where that is too narrow.
    final double above = <double>[
      0,
      for (final Offset o in cellCentres(
        _size,
        activity.cells.length,
        aspect: aspect,
        minCell: minCell,
        text: textRow,
      ))
        if ((o.dx - mistake.dx).abs() < 1 && o.dy < mistake.dy - 1) o.dy + height / 2,
    ].reduce(math.max);
    final double room = mistake.dy - height / 2 - above;
    final double card = (room + 10 * k).clamp(40 * k, 56 * k);
    final double top = math.max(above + 2, mistake.dy - height / 2 - card - 2);
    final double inner = card - 12 * k - 6;
    return <HintMark>[
      CardMark(
        Rect.fromLTWH(mistake.dx - card / 2, top, card, card),
        SizedBox(
          width: inner,
          height: inner,
          child: Center(child: _CellFace(activity, right, inner, look: look)),
        ),
      ),
    ];
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    return ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _RowStage(this, size));
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

class _RowStage extends StatelessWidget {
  const _RowStage(this.s, this.size);

  final SpotErrorSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final SpotErrorActivity a = s.activity;
    final int n = a.cells.length;
    final double side = SpotErrorSession.cellSide(size, n, minCell: s.minCell, text: s.textRow);
    final double height = SpotErrorSession.cellHeight(
      size,
      n,
      aspect: s.aspect,
      minCell: s.minCell,
      text: s.textRow,
    );
    final List<Offset> at = SpotErrorSession.cellCentres(
      size,
      n,
      aspect: s.aspect,
      minCell: s.minCell,
      text: s.textRow,
    );
    final bool oneLine = SpotErrorSession.linesOf(size, n, minCell: s.minCell, text: s.textRow) == 1;
    // A cell has 3 of room round it that its touch counts (the cell is [side] and the room is part of the pitch).
    final double box = side + 6;
    final double boxHeight = height + 6;
    // Every number and sign of the row is one size: the common half of a cell, or less when the longest number would not fit one.
    double textSize = side * 0.5;
    for (final String c in a.cells) {
      if (c.startsWith('n:')) textSize = math.min(textSize, (side - 12) / ((c.length - 2) * 0.6));
    }
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('spot-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fill(
              child: Directionality(
                textDirection: TextDirection.ltr,
                // The cells come one by one from the left, so the child sees where the row starts.
                child: RowEntrance(
                  count: n,
                  builder: (BuildContext context, Widget Function(int, Widget) cell) => Stack(
                    children: <Widget>[
                      for (int i = 0; i < n; i++)
                        Positioned(
                          left: at[i].dx - box / 2,
                          top: at[i].dy - boxHeight / 2,
                          width: box,
                          height: boxHeight,
                          child: cell(i, _cell(a, i, side, height, textSize)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Hint 2: a sky bar under the row grows from the left as the light goes by. It points the way and picks out no cell.
            // It runs along one line only: a row in two lines has the light alone.
            if (s.barTo != null && oneLine)
              Positioned(
                left: at.first.dx - side / 2,
                bottom: 2,
                child: AnimatedContainer(
                  key: const Key('spot-bar'),
                  duration: const Duration(milliseconds: 500),
                  width: box * (s.barTo! + 1) - 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: TokenColors.hintHalo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            Positioned.fill(child: s._hint.body(size)),
          ],
        ),
      ),
    );
  }

  Widget _cell(SpotErrorActivity a, int i, double side, double height, double textSize) {
    final Color? ring = s.wrongCell == i
        ? TokenColors.notYetRing
        : (s.ring == AnswerState.correct && i == a.wrong
              ? TokenColors.correctGlow
              : (s.hintCell == i || s.lit == i ? TokenColors.hintHalo : null));
    return GestureDetector(
      key: Key('cell-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => s.choose(i),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          width: side,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TokenColors.paper.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(TokenRadius.lg),
            border: Border.all(color: ring ?? TokenColors.hairline, width: ring == null ? 3 : 5),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: _CellFace(a, a.cells[i], side, textSize: textSize, look: s.look),
              ),
              if (s.visited.contains(i) && s.hintCell != i)
                const Positioned(top: 4, right: 4, child: SeenDot(key: Key('seen-dot'))),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a cell shows: a picture of the pack (cut to its [look] when the row compares sizes), an arrow, a number or a sign, in a cell whose side is [side]. A sign is drawn as the
/// screen draws it (× for `op:x`, and the child's division sign for `op::`), which is why this is a widget and not a function.
class _CellFace extends StatelessWidget {
  const _CellFace(this.activity, this.cell, this.side, {this.textSize, this.look});

  final SpotErrorActivity activity;
  final String cell;
  final double side;

  /// The size of a number or sign when the row sets one for all its cells; half the cell's side otherwise.
  final double? textSize;

  /// The look of the size pictures of the row (see [SpotErrorSession.lookOf]); null for any other row.
  final SizeLook? look;

  @override
  Widget build(BuildContext context) {
    if (cell.startsWith('asset:')) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: PackSvg(look?.svg(cell) ?? activity.assets.svg(cell)),
      );
    }
    if (cell.startsWith('dir:')) {
      final IconData icon = switch (cell.substring(4)) {
        'up' => Icons.arrow_upward_rounded,
        'down' => Icons.arrow_downward_rounded,
        'left' => Icons.arrow_back_rounded,
        _ => Icons.arrow_forward_rounded,
      };
      return Icon(icon, size: side * 0.6, color: TokenColors.ink);
    }
    final String text = cell.startsWith('op:')
        ? signGlyph(cell.substring(3), MathSigns.of(context))
        : cell.substring(2);
    return Text(text, style: AppText.fixed(size: textSize ?? side * 0.5, weight: 800, lineHeight: 1));
  }
}
