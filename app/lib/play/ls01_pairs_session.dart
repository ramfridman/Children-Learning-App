import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'ls01_metrics.dart';
import 'ls01_session.dart';
import 'ls01_tiles.dart';
import 'response_code.dart';
import 'template_session.dart';

/// Pairs with text, picture or sound faces, played one at a time (LS01, `match_pairs` 1.1; docs/design/languages-l5-ls01.md section 7.4).
///
/// Two rows of tiles at their reading size do not fit a phone, so the item now stands on the stage (square, at the start side) and its
/// partners are the row of the answer zone, as a tap row. A touch on the right one makes the pair, which flies to the stage's end side as a
/// small kept chip, and the next item comes; the last pair makes itself. A wrong touch is "not yet" on that partner and the item now stays.
/// The pairs are the same, and so is the one response: one decision at a time is less to hold in mind.
class Ls01PairsSession extends Ls01Session {
  Ls01PairsSession(super.controller, MatchPairsActivity super.activity, {super.band, super.stress})
    : pairs = activity;

  final MatchPairsActivity pairs;

  /// The item now (an index of the left faces), and the pairs made so far as (left, right) indexes.
  int current = 0;
  final List<(int, int)> made = <(int, int)>[];

  /// The partner whose "not yet" shows.
  String? notYetId;
  bool busy = false;
  bool done = false;

  // A hint's marks: the item now lit, its other form beside it.
  bool itemLit = false;
  bool altShown = false;

  Ls01Face _face(MatchFace f) => Ls01Face(
    id: f.id,
    text: f.text == null
        ? null
        : (stress ? f.text! : String.fromCharCodes(f.text!.runes.where((int r) => r != 0x0301))),
    svg: f.sprite == null ? null : pairs.assets.svg(f.sprite!),
    numeral: f.numeral,
    clip: f.clip,
    label: f.label,
  );

  late final List<Ls01Face> leftFaces = <Ls01Face>[for (final MatchFace f in pairs.left) _face(f)];
  late final List<Ls01Face> rightFaces = <Ls01Face>[for (final MatchFace f in pairs.right) _face(f)];

  /// The partners still to be paired, as indexes of the right faces, in their order.
  List<int> get remaining => <int>[
    for (int i = 0; i < pairs.right.length; i++)
      if (!made.any(((int, int) p) => p.$2 == i)) i,
  ];

  MatchFace get item => pairs.left[current];

  FaceKind get _kind => pairs.right.every((MatchFace f) => f.text != null && isSingleLetter(f.text!))
      ? FaceKind.letter
      : FaceKind.word;

  // ---- the child's moves ----

  /// A touch on the item now: its sound (it is a sound card, or a letter that has its clip).
  void hearItem() {
    final String? clip = item.clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
  }

  /// A touch on partner [rightIndex].
  Future<void> choose(int rightIndex) async {
    if (busy || done) return;
    final MatchFace partner = pairs.right[rightIndex];
    final bool right = pairs.pairs[item.id] == partner.id;
    if (controller.guided && !right) return;
    handTip = null;
    final Ls01Face f = rightFaces[rightIndex];
    if (f.soundOnly) playClips?.call(<String>[f.clip!], replace: true);
    if (right) {
      _pair(rightIndex);
      return;
    }
    busy = true;
    notYetId = partner.id;
    notify();
    await controller.submitPlacement(
      right: false,
      tag: partner.misconception ?? pairs.wrongTag ?? '',
      response: ResponseCode.pair(current, rightIndex),
    );
    if (disposed) return;
    later(TemplateSession.notYetPause, () {
      notYetId = null;
      busy = false;
      notify();
    });
  }

  void _pair(int rightIndex) {
    made.add((current, rightIndex));
    itemLit = false;
    altShown = false;
    if (made.length < pairs.left.length) {
      current = made.length;
      // The last pair makes itself, as in every pairs item.
      final List<int> rest = remaining;
      if (rest.length == 1) {
        made.add((current, rest.single));
      }
    }
    notify();
    if (made.length == pairs.left.length) _finish();
  }

  Future<void> _finish() async {
    busy = true;
    await controller.submitPlacement(right: true, response: ResponseCode.pairs(made));
    if (disposed) return;
    done = true;
    notify();
    later(praise, controller.next);
  }

  // ---- hints ----

  @override
  void resetState() {
    current = 0;
    made.clear();
    notYetId = null;
    busy = false;
    done = false;
  }

  @override
  void clearHintMarks() {
    itemLit = false;
    altShown = false;
  }

  @override
  void playHint(int level) {
    switch (level) {
      case 1:
        itemLit = true;
        hearItem();
      case 2:
        // The item in its other form beside itself (a letter with its key word's picture).
        itemLit = true;
        altShown = item.alt != null;
        hearItem();
      default:
        final int right = pairs.right.indexWhere((MatchFace f) => f.id == pairs.pairs[item.id]);
        final List<int> rest = remaining;
        final RowPlan plan = _plan(rest.length);
        final List<Rect> rects = rowRects(zones, plan, rowDirection);
        step(200, () => handTip = rects[rest.indexOf(right)].topCenter + const Offset(0, 6));
        demoOver(1700);
    }
  }

  RowPlan _plan(int count) => metrics.row(
    <String>[
      for (final Ls01Face f in rightFaces)
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
      builder: (BuildContext c, Widget? _) => Semantics(
        container: true,
        label: pairs.altText,
        child: Stack(
          key: const Key('pairs-stage'),
          clipBehavior: Clip.none,
          children: <Widget>[
            if (!done) Align(alignment: AlignmentDirectional.centerStart, child: _itemNow(spec)),
            Align(alignment: AlignmentDirectional.centerEnd, child: _kept(size)),
          ],
        ),
      ),
    );
  }

  Widget _itemNow(ActivitySpec spec) {
    final double side = spec.stageIsCard ? 200 : 120;
    final Ls01Face f = leftFaces[current];
    final Ls01Metrics m = metrics;
    final Widget face = f.text != null && isSingleLetter(f.text!)
        ? Ls01FaceView(face: f, metrics: m, kind: FaceKind.letter, size: m.size(FaceKind.letter) * 1.25)
        : Ls01FaceView(face: f, metrics: m, kind: FaceKind.word);
    final MatchFace left = pairs.left[current];
    return Directionality(
      textDirection: rowDirection,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GestureDetector(
                key: const Key('pairs-item'),
                behavior: HitTestBehavior.opaque,
                onTap: hearItem,
                child: Container(
                  width: side,
                  height: side,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TokenColors.paper,
                    borderRadius: BorderRadius.circular(TokenRadius.xl),
                    border: Border.all(color: TokenColors.hairline, width: TokenBorder.thick),
                    boxShadow: clayShadows(TokenColors.cardLip, soft16: true),
                  ),
                  child: Semantics(label: left.label, child: face),
                ),
              ),
              if (itemLit)
                const Positioned(
                  left: -6,
                  right: -6,
                  top: -6,
                  bottom: -6,
                  child: IgnorePointer(
                    child: SkyRing(key: Key('pairs-item-glow'), round: false, radius: TokenRadius.xl + 6),
                  ),
                ),
            ],
          ),
          if (altShown && left.alt != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 10),
              child: Container(
                key: const Key('pairs-alt'),
                width: side * 0.7,
                height: side * 0.7,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TokenColors.skyTint,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TokenColors.skyDeep, width: 3),
                ),
                child: PackSvg(pairs.assets.svg(left.alt!)),
              ),
            ),
        ],
      ),
    );
  }

  /// The pairs made, as small chips at the stage's end side: the two faces with a short bar between them.
  Widget _kept(Size size) {
    final Ls01Metrics m = metrics;
    Widget small(Ls01Face f) => SizedBox(
      width: 40,
      height: 36,
      child: Ls01FaceView(face: f, metrics: m, kind: FaceKind.kept),
    );
    return SizedBox(
      width: size.width * 0.34,
      child: Wrap(
        key: const Key('pairs-kept'),
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final (int l, int r) in made)
            Directionality(
              textDirection: rowDirection,
              child: Container(
                key: Key('pair-chip-$l-$r'),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: TokenColors.mist, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    small(leftFaces[l]),
                    Container(width: 10, height: 3, color: TokenColors.lilacDeep),
                    small(rightFaces[r]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    seen(spec);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) {
        final List<int> rest = remaining;
        if (done || rest.isEmpty) return const SizedBox.shrink();
        return Ls01Row(
          key: const Key('pairs-row'),
          faces: <Ls01Face>[for (final int i in rest) rightFaces[i]],
          looks: <Ls01Look>[
            for (final int i in rest)
              Ls01Look(
                state: notYetId == pairs.right[i].id ? AnswerState.notYet : AnswerState.idle,
                heard: true,
              ),
          ],
          metrics: metrics,
          direction: rowDirection,
          kind: _kind,
          zoneWidth: spec.tilesWidth,
          plan: _plan(rightFaces.length),
          onTap: (int k) => choose(rest[k]),
        );
      },
    );
  }
}
