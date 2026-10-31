import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../content/schemas.dart' show coinSprites;
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import 'hint_widgets.dart' show DotRow;
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart' show hintScale;
import 'hints/hint_player.dart';
import 'hints/pointer_plans.dart';
import 'hints/tile_points.dart';
import 'shop_pay_session.dart' show CoinFace;
import 'sprite_group.dart';
import 'response_code.dart';
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

  /// The faces the help has lit. A card alone is "start with this one"; the face it goes with is lit only at the end of the
  /// worked example.
  String? hintLeft;
  String? hintRight;
  bool demoRunning = false;
  int _run = 0;
  AnswerState ring = AnswerState.idle;
  bool _busy = false;

  /// The pointing hand, the line it draws and the dots under a numeral (B-40), and the stage's and the board's sizes they use.
  late final HintPlayer _hint = HintPlayer(this);
  Size _size = Size.zero;
  ActivitySpec? _spec;

  bool get _canDraw => _spec != null && !_size.isEmpty;

  /// A face's side in a row of [n] faces over [width] by [height], and where the faces stand: a row is centred and drawn left to
  /// right, each face with 5 around it. The top row is in the stage, the bottom row in the tiles' box.
  static double faceSide(double width, double height, int n) =>
      math.min(height - 12, math.min(96, width / n - 14));

  static double _rowStart(double width, int n, double side) => (width - n * (side + 10)) / 2;

  static Rect topFace(Size stage, int n, int i) {
    final double side = faceSide(stage.width, stage.height, n);
    return Rect.fromCenter(
      center: Offset(_rowStart(stage.width, n, side) + (i + 0.5) * (side + 10), stage.height / 2),
      width: side,
      height: side,
    );
  }

  /// The fingertip place on the top edge of bottom face [i] of [n] (a tile's top, 5 under the box's top).
  static Offset bottomTip(ActivitySpec spec, int n, int i) {
    final double side = faceSide(spec.tilesWidth, 110, n);
    return spec.fromTiles(_rowStart(spec.tilesWidth, n, side) + (i + 0.5) * (side + 10), 5);
  }

  int numberOf(String leftId) => matched.keys.toList().indexOf(leftId) + 1;
  int? numberOfRight(String rightId) {
    for (final MapEntry<String, String> e in matched.entries) {
      if (e.value == rightId) return numberOf(e.key);
    }
    return null;
  }

  bool isMatchedRight(String id) => matched.containsValue(id);

  /// The count of the largest set among the picture faces of both rows (1 when no face is a set).
  late final int largestSet = <MatchFace>[
    ...activity.left,
    ...activity.right,
  ].where((MatchFace f) => f.sprite != null).fold(1, (int most, MatchFace f) => math.max(most, f.count));

  /// Where a face stands in its row: what the written answer names (a face id can be long, an index cannot).
  int _top(String id) => activity.left.indexWhere((MatchFace f) => f.id == id);
  int _bottom(String id) => activity.right.indexWhere((MatchFace f) => f.id == id);
  (int, int) _indexes(String top, String bottom) => (_top(top), _bottom(bottom));

  /// The pair the guide has joined for a moment, and the end of its demonstration when the child touches a card.
  String? _demoPair;

  void _endDemo() {
    if (!demoRunning) return;
    _hint.clear();
    _run++;
    if (_demoPair != null) matched.remove(_demoPair);
    _demoPair = null;
    demoRunning = false;
    controller.demoDone();
  }

  Future<void> tap(String id, {required bool top}) async {
    _endDemo();
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
      if (controller.answerShown) _point();
      notify();
      return;
    }
    _busy = true;
    if (right) {
      _hint.clear();
      matched[l] = r;
      selectedLeft = null;
      selectedRight = null;
      hintLeft = null;
      hintRight = null;
      notify();
      if (matched.length == activity.pairs.length) {
        await controller.submitPlacement(
          right: true,
          response: ResponseCode.pairs(<(int, int)>[
            for (final MapEntry<String, String> e in matched.entries) _indexes(e.key, e.value),
          ]),
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
    await controller.submitPlacement(
      right: false,
      tag: activity.wrongTag ?? '',
      response: ResponseCode.pair(_top(l), _bottom(r)),
    );
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
      if (controller.answerShown) _point();
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
    _hint.clear();
    _run++;
    _demoPair = null;
    matched.clear();
    selectedLeft = null;
    selectedRight = null;
    wrongLeft = null;
    wrongRight = null;
    hintLeft = null;
    hintRight = null;
    ring = AnswerState.idle;
    _busy = false;
    demoRunning = false;
    notify();
  }

  @override
  void onReplay() {
    _hint.clear();
    _run++;
    hintLeft = null;
    hintRight = null;
    notify();
  }

  /// The first pair that is not joined yet.
  MapEntry<String, String>? get _nextPair {
    for (final MapEntry<String, String> e in activity.pairs.entries) {
      if (!matched.containsKey(e.key)) return e;
    }
    return null;
  }

  @override
  void onHint() {
    if ((_busy && !controller.guided) || demoRunning) return;
    switch (hintPictureOf(activity)) {
      case HintPicture.eachFace:
        _lightEach();
      case HintPicture.firstFace:
        _run++;
        _hint.clear();
        hintLeft = _nextPair?.key;
        hintRight = null;
        _anotherWay();
        notify();
      default:
        _drawOne();
    }
  }

  /// Hint 1: the cards of the top row are lit one after the other, from the left. None is joined and none stays lit.
  void _lightEach() {
    _run++;
    final int run = _run;
    hintRight = null;
    final List<String> ids = <String>[
      for (final MatchFace f in activity.left)
        if (!matched.containsKey(f.id)) f.id,
    ];
    for (int i = 0; i < ids.length; i++) {
      later(Duration(milliseconds: 700 * i), () {
        if (run != _run) return;
        hintLeft = ids[i];
        notify();
      });
    }
    later(Duration(milliseconds: 700 * ids.length), () {
      if (run != _run) return;
      hintLeft = null;
      notify();
    });
    notify();
  }

  /// Another way to see the first card, in a sky strip over its lower part, and it stays while the item is open: a numeral shows that
  /// many dots; a coin shows what it is worth as that many dots (a coin of agorot has no strip, it is not a whole number of
  /// shekels); a solid shows the print its face leaves, a dashed outline. A card that is none of these gets nothing.
  void _anotherWay() {
    final MapEntry<String, String>? pair = _nextPair;
    if (pair == null || !_canDraw) return;
    final int i = _top(pair.key);
    final MatchFace card = activity.left[i];
    final Rect face = topFace(_size, activity.left.length, i);
    final double k = hintScale(_size);
    final int? dots = card.numeral ?? _shekels(card.coin);
    final GhostKind? footprint = _printOf(card.sprite);
    final List<HintMark> shown;
    if (dots != null && dots >= 1) {
      shown = <HintMark>[
        CardMark(
          Rect.fromLTWH(face.left + 8 * k, face.bottom - 26 * k, face.width - 16 * k, 20 * k),
          DotRow(count: dots, size: 9 * k),
          tight: true,
        ),
      ];
    } else if (footprint != null) {
      final Rect strip = Rect.fromLTWH(face.left + 12 * k, face.bottom - 44 * k, face.width - 24 * k, 38 * k);
      shown = <HintMark>[
        CardMark(strip, const SizedBox.shrink(), tight: true),
        GhostMark(Rect.fromCenter(center: strip.center, width: 34 * k, height: 34 * k), footprint),
      ];
    } else {
      return;
    }
    _hint.play(HintPlan(const <HintFrame>[], rest: shown));
  }

  /// A coin's value in whole shekels (`s5` is 5), or null for a coin of agorot.
  static int? _shekels(String? coin) {
    final RegExpMatch? m = RegExp(r'^s(\d+)$').firstMatch(coin ?? '');
    return m == null ? null : int.parse(m[1]!);
  }

  /// The print the face of a solid leaves when it is pressed on sand, by its picture's name; null for anything that is not a solid.
  static GhostKind? _printOf(String? sprite) => switch ((sprite ?? '').replaceFirst('asset:solid_', '')) {
    'cylinder' || 'cone' || 'sphere' => GhostKind.circle,
    'pyramid' => GhostKind.triangle,
    'box' => GhostKind.rect,
    _ => null,
  };

  /// The worked example: the pointing hand goes to the first card, then to its partner and draws the line between them (the guide
  /// joins them for a moment), undoes it and leaves the two lit. Then it is the child's turn.
  void _drawOne() {
    final MapEntry<String, String>? pair = _nextPair;
    if (pair == null) return;
    _run++;
    final int run = _run;
    demoRunning = true;
    hintLeft = pair.key;
    hintRight = null;
    selectedLeft = null;
    selectedRight = null;
    final ActivitySpec? spec = _spec;
    if (spec != null && _canDraw) {
      final Rect face = topFace(_size, activity.left.length, _top(pair.key));
      final Offset bottom = bottomTip(spec, activity.right.length, _bottom(pair.value));
      _hint.play(
        handTourPlan(<HandStop>[
          HandStop(face.center, 900),
          HandStop(bottom, 900),
          HandStop(
            bottom,
            1200,
            marks: <HintMark>[
              PairsMark(lines: <(Offset, Offset)>[(Offset(face.center.dx, face.bottom), bottom)]),
            ],
          ),
        ]),
      );
    }
    later(const Duration(milliseconds: 900), () {
      if (run != _run) return;
      hintRight = pair.value;
      notify();
    });
    later(const Duration(milliseconds: 1800), () {
      if (run != _run) return;
      matched[pair.key] = pair.value;
      _demoPair = pair.key;
      notify();
    });
    later(const Duration(milliseconds: 3000), () {
      if (run != _run) return;
      matched.remove(pair.key);
      _demoPair = null;
      demoRunning = false;
      notify();
      controller.demoDone();
    });
    notify();
  }

  // ---- drawing ----

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _size = size;
    _spec = spec;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(
          container: true,
          label: activity.altText,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: _Row(this, activity.left, top: true, width: size.width, height: size.height),
              ),
              Positioned.fill(child: _hint.body(size)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

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
    final double side = MatchPairsSession.faceSide(width, height, faces.length);
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
    final int most = s.largestSet;
    if (most <= 1) return PackSvg(svg);
    // Fair sizes (M9 §13): where the faces are sets, every picture of every set is as big as one of the largest set, so a
    // set of one is never a big picture next to small ones (that would teach M-CNT-SIZE).
    return SpriteGroup(svg: svg, count: f.count, arrangement: 'line', seed: f.count, lineSlots: most);
  }
}
