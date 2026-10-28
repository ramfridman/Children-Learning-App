import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../content/schemas.dart' show coinSprites;
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'shop_pay_session.dart' show CoinFace;
import 'sprite_group.dart';
import 'template_session.dart';

/// The matching template (T16): a row of faces above, a row below, and a face for each in the other row. The child touches a face
/// in one row and a face in the other. A right pair stays joined (both faces get the same number and a green edge); a wrong pair
/// is a "not yet" with the misconception of the activity, and both faces are free again. When every face is joined the activity is
/// right. After three wrong pairs only the right pair is taken, and the help lights it.
///
/// The rows are read from the left, whatever the language.
class MatchPairsSession extends TemplateSession {
  MatchPairsSession(super.controller, this.activity);

  final MatchPairsActivity activity;

  String? selectedLeft;
  String? selectedRight;

  /// Joined pairs: the id of the top face -> the id of the bottom face.
  final Map<String, String> matched = <String, String>{};
  String? wrongLeft;
  String? wrongRight;
  String? hintLeft;
  String? hintRight;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  int numberOf(String leftId) => matched.keys.toList().indexOf(leftId) + 1;
  int? numberOfRight(String rightId) {
    for (final MapEntry<String, String> e in matched.entries) {
      if (e.value == rightId) return numberOf(e.key);
    }
    return null;
  }

  bool isMatchedRight(String id) => matched.containsValue(id);

  Future<void> tap(String id, {required bool top}) async {
    if (_busy || ring == AnswerState.correct) return;
    if (top ? matched.containsKey(id) : isMatchedRight(id)) return;
    if (top) {
      selectedLeft = selectedLeft == id ? null : id;
    } else {
      selectedRight = selectedRight == id ? null : id;
    }
    hintLeft = null;
    hintRight = null;
    notify();
    if (selectedLeft != null && selectedRight != null) await _join(selectedLeft!, selectedRight!);
  }

  Future<void> _join(String l, String r) async {
    final bool right = activity.pairs[l] == r;
    if (controller.guided && !right) {
      selectedLeft = null;
      selectedRight = null;
      _point();
      return;
    }
    _busy = true;
    if (right) {
      matched[l] = r;
      selectedLeft = null;
      selectedRight = null;
      hintLeft = null;
      hintRight = null;
      notify();
      if (matched.length == activity.pairs.length) {
        await controller.submitPlacement(
          right: true,
          response: matched.entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}').join(','),
        );
        if (disposed) return;
        ring = AnswerState.correct;
        notify();
        later(TemplateSession.praisePause, controller.next);
      } else {
        _busy = false;
      }
      return;
    }
    await controller.submitPlacement(right: false, tag: activity.wrongTag ?? '', response: '$l=$r');
    if (disposed) return;
    wrongLeft = l;
    wrongRight = r;
    ring = AnswerState.notYet;
    notify();
    later(TemplateSession.notYetPause, () {
      wrongLeft = null;
      wrongRight = null;
      selectedLeft = null;
      selectedRight = null;
      ring = AnswerState.idle;
      _busy = false;
      if (controller.guided) _point();
      notify();
    });
  }

  void _point() {
    for (final MapEntry<String, String> e in activity.pairs.entries) {
      if (!matched.containsKey(e.key)) {
        hintLeft = e.key;
        hintRight = e.value;
        break;
      }
    }
    notify();
  }

  @override
  void onReset() {
    matched.clear();
    selectedLeft = null;
    selectedRight = null;
    wrongLeft = null;
    wrongRight = null;
    hintLeft = null;
    hintRight = null;
    ring = AnswerState.idle;
    _busy = false;
    notify();
  }

  @override
  void onReplay() {
    hintLeft = null;
    hintRight = null;
    notify();
  }

  @override
  void onHint() {
    if (!_busy) _point();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: Semantics(
        container: true,
        label: activity.altText,
        child: _Row(this, activity.left, top: true, width: size.width, height: size.height),
      ),
    ),
  );

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => Directionality(
      textDirection: TextDirection.ltr,
      child: _Row(this, activity.right, top: false, width: spec.tilesWidth, height: 110),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.s, this.faces, {required this.top, required this.width, required this.height});

  final MatchPairsSession s;
  final List<MatchFace> faces;
  final bool top;
  final double width;
  final double height;

  static const List<Color> _pairColours = <Color>[
    Color(0xFF4DA3FF),
    Color(0xFFFF9F43),
    Color(0xFF9B6BDF),
    Color(0xFF4CAF50),
    Color(0xFFE5484D),
  ];

  @override
  Widget build(BuildContext context) {
    final double side = math.min(height - 12, math.min(96, width / faces.length - 14));
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[for (final MatchFace f in faces) _face(f, side)],
      ),
    );
  }

  Widget _face(MatchFace f, double side) {
    final int? joined = top ? (s.matched.containsKey(f.id) ? s.numberOf(f.id) : null) : s.numberOfRight(f.id);
    final bool selected = top ? s.selectedLeft == f.id : s.selectedRight == f.id;
    final bool wrong = top ? s.wrongLeft == f.id : s.wrongRight == f.id;
    final bool hinted = top ? s.hintLeft == f.id : s.hintRight == f.id;
    final Color edge = wrong
        ? TokenColors.notYetRing
        : (joined != null
              ? _pairColours[(joined - 1) % _pairColours.length]
              : (hinted ? TokenColors.hintHalo : (selected ? TokenColors.ink : TokenColors.hairline)));
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Semantics(
        button: true,
        label: f.label,
        child: GestureDetector(
          key: Key('${top ? 'top' : 'bottom'}-${f.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => s.tap(f.id, top: top),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: side,
                height: side,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TokenColors.paper,
                  borderRadius: BorderRadius.circular(TokenRadius.lg),
                  border: Border.all(
                    color: edge,
                    width: joined != null || selected || hinted || wrong ? 5 : 3,
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: _content(f, side),
              ),
              if (joined != null)
                Positioned(
                  right: -4,
                  top: -6,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: edge,
                    child: Text(
                      '$joined',
                      style: AppText.fixed(
                        size: 13,
                        weight: 800,
                        lineHeight: 1,
                      ).copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(MatchFace f, double side) {
    if (f.coin != null) {
      return FittedBox(
        child: CoinFace(kind: f.coin!, svg: s.activity.assets.svg('asset:${coinSprites[f.coin]}')),
      );
    }
    if (f.numeral != null) {
      return FittedBox(
        child: Text('${f.numeral}', style: AppText.fixed(size: side * 0.6, weight: 800, lineHeight: 1)),
      );
    }
    final String svg = s.activity.assets.svg(f.sprite!);
    if (f.count <= 1) return PackSvg(svg);
    return SpriteGroup(svg: svg, count: f.count, arrangement: 'line', seed: f.count);
  }
}
