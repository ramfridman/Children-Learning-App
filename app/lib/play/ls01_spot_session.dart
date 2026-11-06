import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../design/components.dart' show AnswerState;
import '../content/models.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/tokens.g.dart';
import 'ls01_metrics.dart';
import 'ls01_session.dart';
import 'ls01_tiles.dart';
import 'template_session.dart';

/// Spot the difference with text cells (LS01, `spot_error` 1.1; docs/design/languages-l5-ls01.md section 7.5).
///
/// The stage holds the model, a picture whose word is heard on a touch; the answer zone holds the row of cells, letters, units or words at
/// their reading size, one of which does not match. A touch on a cell chooses it and the item is checked on that touch. Hint level 1 plays
/// the model's word and draws a sky bead over the cells one after the other (the cells themselves do not light); level 2 sets the model's own
/// spelling in a sky card over the stage, cell above cell; level 3 puts the hand on the wrong cell and the right letter appears in it.
class Ls01SpotSession extends Ls01Session {
  Ls01SpotSession(super.controller, SpotErrorActivity super.activity, {super.band, super.stress})
    : spot = activity;

  final SpotErrorActivity spot;

  String? chosen;
  AnswerState chosenState = AnswerState.idle;
  bool busy = false;

  // A hint's marks: the bead over a cell, the card of the model's spelling, the cell put right.
  int? bead;
  bool spellingShown = false;
  bool fixedShown = false;

  List<String> get _texts => <String>[for (final String c in spot.cells) c.substring('txt:'.length)];

  late final List<Ls01Face> faces = <Ls01Face>[
    for (final (int i, String t) in _texts.indexed) Ls01Face(id: 'c$i', text: _show(t), label: t),
  ];

  String _show(String t) => stress ? t : String.fromCharCodes(t.runes.where((int r) => r != 0x0301));

  FaceKind get _kind => _texts.every(isSingleLetter) ? FaceKind.letter : FaceKind.word;

  /// The cell with its wrong one put right, once the third hint shows it.
  List<Ls01Face> get shown {
    final List<String> spelling = spot.model?.spelling ?? const <String>[];
    if (!fixedShown || spelling.length != faces.length) return faces;
    return <Ls01Face>[
      for (final (int i, Ls01Face f) in faces.indexed)
        i == spot.wrong ? Ls01Face(id: f.id, text: spelling[i].substring('txt:'.length), label: f.label) : f,
    ];
  }

  // ---- the child's moves ----

  void hearModel() {
    final String? clip = spot.model?.clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
  }

  Future<void> choose(int cell) async {
    if (busy || chosenState == AnswerState.correct) return;
    final bool right = cell == spot.wrong;
    if (controller.guided && !right) return;
    busy = true;
    handTip = null;
    chosen = 'c$cell';
    notify();
    final out = await controller.submitPlacement(
      right: right,
      tag: right ? '' : (spot.wrongTag ?? ''),
      response: '$cell',
    );
    if (disposed) return;
    if (out.settled || out.correct) {
      chosenState = out.settled ? AnswerState.selected : AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        chosen = null;
        chosenState = AnswerState.idle;
        busy = false;
        notify();
      });
    }
  }

  // ---- hints ----

  @override
  void resetState() {
    chosen = null;
    chosenState = AnswerState.idle;
    busy = false;
  }

  @override
  void clearHintMarks() {
    bead = null;
    spellingShown = false;
    fixedShown = false;
  }

  @override
  void playHint(int level) {
    final int n = faces.length;
    switch (level) {
      case 1:
        hearModel();
        for (int i = 0; i < n; i++) {
          step(650 * i, () => bead = i);
        }
        step(650 * n, () => bead = null);
      case 2:
        spellingShown = true;
        hearModel();
      default:
        final List<Rect> rects = rowRects(
          zones,
          Ls01Row.planOf(faces, metrics, _kind, zones.tilesWidth),
          rowDirection,
        );
        step(200, () => handTip = rects[spot.wrong].topCenter + const Offset(0, 6));
        step(1500, () => fixedShown = (spot.model?.spelling.isNotEmpty ?? false));
        demoOver(2600);
    }
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    seen(spec);
    return Ls01StageBuilder(
      direction: rowDirection,
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final Ls01Metrics m = metrics;
        final double side = (size.height - 12).clamp(60, spec.stageIsCard ? 220 : 136).toDouble();
        final String? picture = spot.model?.sprite;
        return Semantics(
          container: true,
          label: spot.altText,
          child: Stack(
            key: const Key('spot-stage'),
            clipBehavior: Clip.none,
            children: <Widget>[
              if (picture != null)
                Center(
                  child: GestureDetector(
                    key: const Key('spot-model'),
                    behavior: HitTestBehavior.opaque,
                    onTap: hearModel,
                    child: SizedBox(width: side, height: side, child: PackSvg(spot.assets.svg(picture))),
                  ),
                ),
              if (spellingShown && (spot.model?.spelling.isNotEmpty ?? false))
                Positioned(left: 0, right: 0, top: 0, child: Center(child: _spellingCard(m))),
            ],
          ),
        );
      },
    );
  }

  /// The model's own spelling, in a sky card, cell above cell (the row below has the same cells).
  Widget _spellingCard(Ls01Metrics m) {
    final List<Ls01Face> row = <Ls01Face>[
      for (final (int i, String t) in (spot.model!.spelling).indexed)
        Ls01Face(id: 's$i', text: t.substring('txt:'.length), label: t),
    ];
    final RowPlan plan = Ls01Row.planOf(row, m, _kind, zones.tilesWidth);
    return Container(
      key: const Key('spot-spelling'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TokenColors.skyTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TokenColors.hintHalo, width: 3),
      ),
      child: Directionality(
        textDirection: rowDirection,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final Ls01Face f in row)
              SizedBox(
                width: plan.cell * 0.6,
                height: plan.tileHeight * 0.6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: plan.cell,
                    height: plan.tileHeight,
                    child: Ls01FaceView(face: f, metrics: m, kind: _kind),
                  ),
                ),
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
        final List<Ls01Face> row = shown;
        final RowPlan plan = Ls01Row.planOf(row, metrics, _kind, spec.tilesWidth);
        final List<Rect> rects = rowRects(spec, plan, rowDirection);
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Ls01Row(
              key: const Key('spot-row'),
              faces: row,
              looks: <Ls01Look>[
                for (final Ls01Face f in row)
                  Ls01Look(state: chosen == f.id ? chosenState : AnswerState.idle),
              ],
              metrics: metrics,
              direction: rowDirection,
              kind: _kind,
              zoneWidth: spec.tilesWidth,
              onTap: (int i) => choose(i),
            ),
            // The bead of the first hint: a sky dot over a cell, the cells themselves unlit.
            if (bead != null)
              Positioned(
                left: rects[bead!].center.dx - spec.tilesLeft - 9,
                top: -4,
                child: IgnorePointer(
                  child: Container(
                    key: const Key('spot-bead'),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: TokenColors.skyDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: TokenColors.paper, width: 3),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
