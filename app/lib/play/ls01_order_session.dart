import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'ls01_metrics.dart';
import 'ls01_sentence.dart' show DashedBoxPainter;
import 'ls01_session.dart';
import 'ls01_tiles.dart';
import 'response_code.dart';
import 'template_session.dart';

/// Order tiles with text or picture faces (LS01, `build_pattern` 1.1; docs/design/languages-l5-ls01.md section 7.6): "put the letters in
/// order", "what comes next". The stage holds the row, cells of 52 by 64 on the phones (72 by 88 on the tablets) with the places to fill, dashed,
/// at the row's end in the course's direction; the answer zone holds the tiles. A tile is touched or dragged to the next empty place; a touch
/// on a filled place takes its tile back. The row is checked when every place is filled.
class Ls01OrderSession extends Ls01Session {
  Ls01OrderSession(super.controller, BuildPatternActivity super.activity, {super.band, super.stress})
    : pattern = activity,
      filled = List<int?>.filled(activity.slots, null);

  final BuildPatternActivity pattern;

  /// For each place the palette index of the tile in it, or null while it is empty.
  final List<int?> filled;
  final Set<int> wobbling = <int>{};
  bool busy = false;
  bool done = false;

  // A hint's marks: the cell of the model lit now, the last cell and the next place joined.
  int? litCell;
  bool bridge = false;

  Ls01Face _face(String f, int i) => f.startsWith('txt:')
      ? Ls01Face(
          id: 'p$i',
          text: stress
              ? f.substring(4)
              : String.fromCharCodes(f.substring(4).runes.where((int r) => r != 0x0301)),
          label: f.substring(4),
        )
      : Ls01Face(id: 'p$i', svg: pattern.assets.svg(f), label: f);

  late final List<Ls01Face> palette = <Ls01Face>[
    for (final (int i, String f) in pattern.palette.indexed) _face(f, i),
  ];
  late final List<Ls01Face> modelFaces = <Ls01Face>[
    for (final (int i, String f) in pattern.model.indexed) _face(f, 100 + i),
  ];

  FaceKind get _kind =>
      pattern.palette.every((String f) => f.startsWith('txt:') && isSingleLetter(f.substring(4)))
      ? FaceKind.letter
      : FaceKind.word;

  /// The tiles still in the tray, as palette indexes.
  List<int> get tray => <int>[
    for (int i = 0; i < palette.length; i++)
      if (!filled.contains(i)) i,
  ];

  int? get nextEmpty {
    final int i = filled.indexOf(null);
    return i < 0 ? null : i;
  }

  // ---- the child's moves ----

  /// Tile [paletteIndex] goes to [place], or to the next empty place.
  void place(int paletteIndex, {int? place}) {
    if (busy || done || filled.contains(paletteIndex)) return;
    final int? at = place != null && filled[place] == null ? place : nextEmpty;
    if (at == null) return;
    // After three tries only the right tile takes a place.
    if (controller.guided && pattern.palette[paletteIndex] != pattern.sequence[at]) return;
    handTip = null;
    filled[at] = paletteIndex;
    notify();
    if (!filled.contains(null)) _check();
  }

  void takeBack(int placeIndex) {
    if (busy || done || filled[placeIndex] == null) return;
    filled[placeIndex] = null;
    notify();
  }

  Future<void> _check() async {
    busy = true;
    final List<int> wrong = <int>[
      for (int i = 0; i < filled.length; i++)
        if (pattern.palette[filled[i]!] != pattern.sequence[i]) i,
    ];
    final String code = ResponseCode.pattern(filled);
    if (wrong.isEmpty) {
      await controller.submitPlacement(right: true, response: code);
      if (disposed) return;
      done = true;
      notify();
      later(praise, controller.next);
      return;
    }
    await controller.submitPlacement(right: false, tag: pattern.wrongTag ?? '', response: code);
    if (disposed) return;
    wobbling
      ..clear()
      ..addAll(wrong);
    notify();
    later(TemplateSession.notYetPause, () {
      for (final int w in wobbling) {
        filled[w] = null;
      }
      wobbling.clear();
      busy = false;
      notify();
    });
  }

  // ---- hints ----

  @override
  void resetState() {
    filled.fillRange(0, filled.length, null);
    wobbling.clear();
    busy = false;
    done = false;
  }

  @override
  void clearHintMarks() {
    litCell = null;
    bridge = false;
  }

  @override
  void playHint(int level) {
    final int n = pattern.model.length;
    switch (level) {
      case 1:
        // The row lights in rhythm, cell after cell, and ends on the next place; no tile is lit.
        for (int i = 0; i <= n; i++) {
          step(550 * i, () => litCell = i);
        }
        step(550 * (n + 1), () => litCell = null);
      case 2:
        bridge = true;
      default:
        final int at = nextEmpty ?? 0;
        final int want = pattern.palette.indexOf(pattern.sequence[at]);
        final List<int> rest = tray;
        final List<Rect> rects = rowRects(zones, _plan(rest.length), rowDirection);
        step(200, () => handTip = rects[rest.indexOf(want)].topCenter + const Offset(0, 6));
        demoOver(1700);
    }
  }

  RowPlan _plan(int count) => metrics.row(
    <String>[
      for (final Ls01Face f in palette)
        if (f.text != null) f.text!,
    ],
    _kind,
    zones.tilesWidth,
    count: count,
  );

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    seen(spec);
    return Ls01StageBuilder(
      direction: rowDirection,
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final bool tablet = spec.stageIsCard;
        final double w = tablet ? 72 : 52;
        final double h = tablet ? 88 : 64;
        final Ls01Metrics m = metrics;
        return Semantics(
          container: true,
          label: pattern.altText,
          child: Center(
            child: Directionality(
              textDirection: rowDirection,
              child: Row(
                key: const Key('order-row'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final (int i, Ls01Face f) in modelFaces.indexed)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tablet ? 6 : 4),
                      child: _cell(f, w, h, m, lit: litCell == i || (bridge && i == modelFaces.length - 1)),
                    ),
                  for (int i = 0; i < filled.length; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tablet ? 6 : 4),
                      child: _slot(
                        i,
                        w,
                        h,
                        m,
                        lit: (litCell == modelFaces.length && i == nextEmpty) || (bridge && i == nextEmpty),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// A cell of the model: not a target.
  Widget _cell(Ls01Face f, double w, double h, Ls01Metrics m, {bool lit = false}) => Stack(
    clipBehavior: Clip.none,
    children: <Widget>[
      Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TokenColors.hairline, width: 3),
        ),
        child: _inside(f, m, w, h),
      ),
      if (lit)
        const Positioned.fill(
          child: IgnorePointer(child: SkyRing(key: Key('order-glow'), round: false, radius: 18)),
        ),
    ],
  );

  Widget _inside(Ls01Face f, Ls01Metrics m, double w, double h) => f.text != null
      ? FittedBox(
          fit: BoxFit.scaleDown,
          child: CourseText(
            f.text!,
            course: m.course,
            size: m.size(FaceKind.letter),
            bold: true,
            lineHeight: lineHeightFor(f.text!, hebrew: m.hebrew),
          ),
        )
      : Padding(padding: const EdgeInsets.all(4), child: PackSvg(f.svg!));

  /// A place to fill: dashed while it is empty, solid with its tile in it; a touch on a filled one takes the tile back.
  Widget _slot(int i, double w, double h, Ls01Metrics m, {bool lit = false}) {
    final int? tile = filled[i];
    return DragTarget<int>(
      onWillAcceptWithDetails: (DragTargetDetails<int> d) => !busy && !done && tile == null,
      onAcceptWithDetails: (DragTargetDetails<int> d) => place(d.data, place: i),
      builder: (BuildContext c, List<int?> over, List<dynamic> rejected) => GestureDetector(
        key: Key('order-slot-$i'),
        behavior: HitTestBehavior.opaque,
        onTap: () => takeBack(i),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // The empty place is dashed (docs/design/languages-l5-ls01.md section 7.6); a place with a tile in it, or in its "not yet", is solid.
            if (tile == null && !wobbling.contains(i))
              CustomPaint(
                key: Key('order-slot-dashed-$i'),
                size: Size(w, h),
                painter: DashedBoxPainter(
                  dashed: true,
                  color: TokenColors.lilacDeep,
                  fill: TokenColors.paper.withValues(alpha: 0.6),
                ),
              )
            else
              Container(
                width: w,
                height: h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TokenColors.paper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: wobbling.contains(i) ? TokenColors.notYetRing : TokenColors.hairline,
                    width: 3,
                  ),
                ),
                child: tile == null ? null : _inside(palette[tile], m, w, h),
              ),
            if (lit)
              const Positioned.fill(
                child: IgnorePointer(child: SkyRing(key: Key('order-slot-glow'), round: false, radius: 18)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    seen(spec);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final List<int> rest = tray;
        if (rest.isEmpty) return const SizedBox.shrink();
        final Ls01Metrics m = metrics;
        final RowPlan p = _plan(palette.length);
        return Ls01Row(
          key: const Key('order-tray'),
          faces: <Ls01Face>[for (final int i in rest) palette[i]],
          looks: const <Ls01Look>[],
          metrics: m,
          direction: rowDirection,
          kind: _kind,
          zoneWidth: spec.tilesWidth,
          plan: p,
          onTap: (int k) => place(rest[k]),
          decorate: (int k, Widget tile) => Draggable<int>(
            key: Key('order-card-${rest[k]}'),
            data: rest[k],
            maxSimultaneousDrags: busy || done ? 0 : 1,
            feedback: SizedBox(
              width: p.tileWidth,
              height: p.tileHeight,
              child: Opacity(
                opacity: 0.9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(TokenRadius.xl),
                    border: Border.all(color: TokenColors.selectedRing, width: 4),
                  ),
                  child: Ls01FaceView(face: palette[rest[k]], metrics: m, kind: _kind),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: tile),
            child: tile,
          ),
        );
      },
    );
  }
}
