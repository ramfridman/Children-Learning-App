import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/hint_ladder.dart';
import '../../content/models.dart';
import '../../design/app_text.dart';
import '../count_tap_session.dart' show Dots;
import '../hint_hand.dart';
import '../hint_widgets.dart';
import 'hint_marks.dart';
import 'hint_pictures.dart' show hintScale;
import 'prompt_numbers.dart';
import 'sprite_outline.dart';
import 'tap_geometry.dart';

part 'tap_plans_b.dart';

// What each family of `tap_answer` draws at each hint level (B-40 part 2; the plan is docs/curriculum/b40-visual-hint-ladder.md
// section 5.1, the pictures are docs/design/b40-visual-hints.md section 5). Each level is a [HintPlan]: steps shown one after the
// other, on the stage, over the group, the row or the numeral of the question.
//
//   level 1, look here:      a sky glow on the parts of the question (or, where the stage has none, each option in turn);
//   level 2, another way:    a new picture (a hand, a path, a swatch, an outline, pair lines, brackets, numbered slots);
//   level 3, watch me:       the sky hand does the whole thing, and the answer is the last step.
//
// Level 1 and level 2 never mark the right option. What a plan needs (a colour, a shape, the number given) it reads from the
// activity as it is: the sprite names and counts of its options and groups, and for a number sequence the word "after" or
// "before" of its question. A plan that cannot find what it needs falls back to the generic one, so a hint is never empty.

/// The plan of [a] at [level] (1 to 3), or null when the activity's family has no pictures yet.
HintPlan? tapHintPlan(TapAnswerActivity a, TapGeometry g, int level) {
  final TapFamily? family = tapFamilyOf(a.skillId, numeralOnStage: a.stageNumeral != null);
  if (family == null) return null;
  final _Plans p = _Plans(a, g);
  final int l = level.clamp(1, 3);
  final HintPlan? own = p.bandB(l);
  if (own != null) return own;
  return switch (family) {
    TapFamily.colour => p.colour(l),
    TapFamily.shapes => p.shapes(l),
    TapFamily.compare => p.compare(l),
    TapFamily.count => p.count(l),
    TapFamily.sequence => p.sequence(l),
    TapFamily.pattern => p.pattern(l),
    TapFamily.time => p.time(l),
    TapFamily.same => p.same(l),
    TapFamily.add => p.add(l),
    TapFamily.numerals => p.numerals(l),
    TapFamily.measure => p.measure(l),
    TapFamily.clockMoney => p.generic(l),
  };
}

/// The colour a sprite name says (`ball_red`, `shape_circle_yellow`, `shade_blue_1`: the last part that is a colour), or null.
String? colourOfSprite(String? ref) {
  if (ref == null) return null;
  for (final String part in ref.split('_').reversed) {
    if (hintColours.containsKey(part)) return part;
  }
  return null;
}

/// The words of a number question that say which way the sequence goes, written as code points (every Hebrew string of the app
/// lives in `strings/he.dart`; these two are read, never shown): "before" and "after".
final String _before = String.fromCharCodes(<int>[0x5DC, 0x5E4, 0x5E0, 0x5D9]);
final String _after = String.fromCharCodes(<int>[0x5D0, 0x5D7, 0x5E8, 0x5D9]);

/// "From" (as in "take one from seven"): a question that takes one away, as the word "before" asks for the one before.
final String _from = String.fromCharCodes(<int>[0x5DE, 0x5EA, 0x5D5, 0x5DA]);

/// The Hebrew text of a prompt without its vowel marks, to look for one word.
String _plain(String s) => s.replaceAll(_vowelMarks, '');

final RegExp _vowelMarks = RegExp('[${String.fromCharCode(0x591)}-${String.fromCharCode(0x5C7)}]');

/// The whole words of a prompt, without vowel marks.
Set<String> _wordsOf(String s) => _plain(s).split(_notLetters).toSet();

final RegExp _notLetters = RegExp('[^${String.fromCharCode(0x5D0)}-${String.fromCharCode(0x5EA)}]+');

/// Words a plan reads from a question to choose its picture, written as code points: "to stack", "table", "heavy", "light".
final String _stack = String.fromCharCodes(<int>[0x5DC, 0x5E2, 0x5E8, 0x5DD]);
final String _table = String.fromCharCodes(<int>[0x5E9, 0x5DC, 0x5D7, 0x5DF]);
final String _heavy = String.fromCharCodes(<int>[0x5DB, 0x5D1, 0x5D3]);
final String _light = String.fromCharCodes(<int>[0x5E7, 0x5DC]);

// The pictures a position hint draws of its own (the tiles' red ball and brown box are not copied): a plain box, a bin the toy can
// stand in, and a table the toy can stand under. Each is drawn in a 100 by 100 box, its top edge a little below the box's top.
const String _boxSvg =
    '<svg viewBox="0 0 100 100"><rect x="8" y="22" width="84" height="70" rx="6" fill="#C98F52"/>'
    '<rect x="8" y="22" width="84" height="16" rx="6" fill="#B07A3F"/></svg>';
const String _binSvg =
    '<svg viewBox="0 0 100 100"><path d="M8 40 H92 L82 92 H18 Z" fill="#C98F52"/>'
    '<rect x="6" y="38" width="88" height="8" rx="4" fill="#B07A3F"/></svg>';
const String _tableSvg =
    '<svg viewBox="0 0 100 100"><rect x="4" y="18" width="92" height="10" rx="4" fill="#8A5A2B"/>'
    '<rect x="10" y="28" width="9" height="68" fill="#8A5A2B"/><rect x="81" y="28" width="9" height="68" fill="#8A5A2B"/></svg>';

/// The smallest unit that repeats through the known cells of [row], or null when none does (the unit is at most half the row).
int? periodOf(List<String> row) {
  for (int p = 1; p <= row.length ~/ 2; p++) {
    bool fits = true;
    for (int i = 0; i < row.length && fits; i++) {
      for (int j = i + p; j < row.length; j += p) {
        if (row[i] != '?' && row[j] != '?' && row[i] != row[j]) {
          fits = false;
          break;
        }
      }
    }
    if (fits) return p;
  }
  return null;
}

/// The box the ink of a pack picture covers, as parts of its drawing box (0 to 1 each way): a short stick is drawn in the middle
/// of a box as big as the long one's, so a hint that lines things up or measures them needs the ink, not the box. Reads the plain
/// shapes the pack pictures are made of (rect, circle, ellipse, line, polygon, absolute paths) and one centred `scale` group;
/// anything else counts as the whole box, as does a picture it cannot read (no numbers it can parse, an empty viewBox, a picture
/// over [maxReadableSvgChars]). Never throws. Kept once for each picture.
Rect inkBoxOf(String svg) {
  if (svg.length > maxReadableSvgChars) return _wholeBox;
  return _inkBoxes.putIfAbsent(svg, () => _readInkBox(svg));
}

const Rect _wholeBox = Rect.fromLTWH(0, 0, 1, 1);
final Map<String, Rect> _inkBoxes = <String, Rect>{};

Rect _readInkBox(String svg) {
  const Rect whole = _wholeBox;
  final RegExpMatch? vb = RegExp(r'viewBox="\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)')
      .firstMatch(svg);
  if (vb == null) return whole;
  final double? vx = double.tryParse(vb[1]!);
  final double? vy = double.tryParse(vb[2]!);
  final double? vw = double.tryParse(vb[3]!);
  final double? vh = double.tryParse(vb[4]!);
  if (vx == null || vy == null || vw == null || vh == null || !(vw > 0) || !(vh > 0)) return whole;
  final RegExpMatch? grp = RegExp(
    r'translate\(\s*([-\d.]+)[\s,]+([-\d.]+)\s*\)\s*scale\(\s*([\d.]+)\s*\)\s*translate\(',
  ).firstMatch(svg);
  final double? px = grp == null ? 0 : double.tryParse(grp[1]!);
  final double? py = grp == null ? 0 : double.tryParse(grp[2]!);
  final double? sc = grp == null ? 1 : double.tryParse(grp[3]!);
  if (px == null || py == null || sc == null) return whole;
  final Offset pivot = Offset(px, py);
  final double scale = sc;
  double minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
  void add(double x, double y) {
    final Offset p = pivot + (Offset(x, y) - pivot) * scale;
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx);
    maxY = math.max(maxY, p.dy);
  }

  for (final (String tag, String at) in svgTags(svg, 'rect|circle|ellipse|line|polygon|polyline|path')) {
    double v(String name) =>
        double.tryParse(
          RegExp(
                r'\b'
                '$name'
                r'="([-\d.]+)"',
              ).firstMatch(at)?[1] ??
              '',
        ) ??
        0;
    switch (tag) {
      case 'rect':
        add(v('x'), v('y'));
        add(v('x') + v('width'), v('y') + v('height'));
      case 'circle':
        add(v('cx') - v('r'), v('cy') - v('r'));
        add(v('cx') + v('r'), v('cy') + v('r'));
      case 'ellipse':
        add(v('cx') - v('rx'), v('cy') - v('ry'));
        add(v('cx') + v('rx'), v('cy') + v('ry'));
      case 'line':
        add(v('x1'), v('y1'));
        add(v('x2'), v('y2'));
      case 'polygon' || 'polyline':
        final List<double?> read = <double?>[
          for (final RegExpMatch d in RegExp(
            r'-?[\d.]+',
          ).allMatches(RegExp(r'points="([^"]*)"').firstMatch(at)?[1] ?? ''))
            double.tryParse(d[0]!),
        ];
        if (read.contains(null)) return whole;
        final List<double> n = <double>[for (final double? v in read) v!];
        for (int i = 0; i + 1 < n.length; i += 2) {
          add(n[i], n[i + 1]);
        }
      default:
        final String d = RegExp(r'\bd="([^"]*)"').firstMatch(at)?[1] ?? '';
        // Relative moves and arcs are not read: the whole box.
        if (RegExp('[a-yA]').hasMatch(d.replaceAll('e-', ''))) return whole;
        String cmd = 'M';
        final List<double> nums = <double>[];
        void flush() {
          if (cmd == 'H') {
            for (final double x in nums) {
              add(x, minY.isFinite ? minY : 0);
            }
          } else if (cmd == 'V') {
            for (final double y in nums) {
              add(minX.isFinite ? minX : 0, y);
            }
          } else {
            for (int i = 0; i + 1 < nums.length; i += 2) {
              add(nums[i], nums[i + 1]);
            }
          }
          nums.clear();
        }

        for (final RegExpMatch t in RegExp(r'[A-Za-z]|-?\d*\.?\d+').allMatches(d)) {
          final String tok = t[0]!;
          if (RegExp('[A-Za-z]').hasMatch(tok)) {
            flush();
            cmd = tok;
          } else {
            nums.add(double.parse(tok));
          }
        }
        flush();
    }
  }
  if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) return whole;
  return Rect.fromLTRB(
    ((minX - vx) / vw).clamp(0, 1).toDouble(),
    ((minY - vy) / vh).clamp(0, 1).toDouble(),
    ((maxX - vx) / vw).clamp(0, 1).toDouble(),
    ((maxY - vy) / vh).clamp(0, 1).toDouble(),
  );
}

/// [svg] with its viewBox cut down to [part] (parts of the box, as [inkBoxOf] gives them) and no fixed size, so that it draws
/// only that part, filling a box of the same shape.
String cropToInk(String svg, Rect part) {
  final RegExpMatch? vb = RegExp(r'viewBox="\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)\s*"')
      .firstMatch(svg);
  if (vb == null) return svg;
  final double? vx = double.tryParse(vb[1]!);
  final double? vy = double.tryParse(vb[2]!);
  final double? vw = double.tryParse(vb[3]!);
  final double? vh = double.tryParse(vb[4]!);
  if (vx == null || vy == null || vw == null || vh == null || !(vw > 0) || !(vh > 0)) return svg;
  String f(double v) => v.toStringAsFixed(2);
  final String box =
      'viewBox="${f(vx + part.left * vw)} ${f(vy + part.top * vh)} ${f(part.width * vw)} ${f(part.height * vh)}"';
  final int start = math.max(0, svg.indexOf('<svg'));
  final int end = svg.indexOf('>', start);
  if (end < 0) return svg;
  final String head = svg
      .substring(start, end)
      .replaceFirst(vb[0]!, box)
      .replaceAll(RegExp(r'\s(width|height)="[^"]*"'), '');
  return svg.substring(0, start) + head + svg.substring(end);
}

/// [svg] cut to its ink, with a little room for its stroke (see [inkBoxOf] and [cropToInk]), and the ink's width over its
/// height. A picture with a wide margin (a ladybug, an apple) then fills the place it is drawn in. Kept once for each picture.
(String, double) inkedSvg(String svg) => _inked.putIfAbsent(svg, () {
  final Rect ink = inkBoxOf(svg);
  final Rect part = Rect.fromLTRB(
    math.max(0, ink.left - 0.02),
    math.max(0, ink.top - 0.02),
    math.min(1, ink.right + 0.02),
    math.min(1, ink.bottom + 0.02),
  );
  return (cropToInk(svg, part), part.width / part.height);
});

final Map<String, (String, double)> _inked = <String, (String, double)>{};

class _Plans {
  _Plans(this.a, this.g) : k = hintScale(g.size);

  final TapAnswerActivity a;
  final TapGeometry g;
  final double k;

  // ---- small helpers ----

  Duration _ms(int ms) => Duration(milliseconds: ms);

  int get _n => a.options.length;
  int get _ci => g.correctIndex;
  ChoiceOption get _right => a.options[_ci];

  String? _svg(String? ref) => ref == null ? null : a.assets.svgOrNull(ref);

  /// The picture of an option (a sprite, or the sprite of its set).
  String? _spriteOf(ChoiceOption o) => o.sprite ?? o.set?.sprite;

  /// A plan that ends with the answer: its last step hands the turn back, and the answer gets its halo.
  HintPlan _demo(List<HintFrame> frames) => HintPlan(frames, endsDemo: true);

  /// The last step of a demonstration: the hand on the right tile (or the right picture on the stage), with [base] still shown.
  HintFrame _toAnswer(List<HintMark> base, {double reserve = 0}) => HintFrame(
    <HintMark>[...base, HandMark(g.optionTip(_ci), press: true)],
    hold: _ms(1300),
    reserve: reserve,
  );

  /// The hand goes along the other options (tiles) one after the other and ends on the right one: the demonstration of a question
  /// that has nothing else to do. The answer is the end of the demonstration, never shown before its last step.
  HintPlan _walkOptions({List<HintMark> base = const <HintMark>[], double reserve = 0}) {
    final List<int> order = <int>[
      for (int i = 0; i < _n; i++)
        if (i != _ci) i,
      _ci,
    ];
    return _demo(<HintFrame>[
      for (final int i in order)
        HintFrame(
          <HintMark>[...base, HandMark(g.optionTip(i), press: true)],
          hold: _ms(i == _ci ? 1300 : 850),
          reserve: reserve,
        ),
    ]);
  }

  /// Level 1 of a question with a group, a row or a numeral on the stage: the parts of the question stand out. With nothing on the
  /// stage, the options are lit one after the other (each the same, none staying lit).
  HintPlan look() {
    final List<Rect> holes = _questionParts();
    if (holes.isEmpty) return tilesInTurn();
    return HintPlan(<HintFrame>[
      HintFrame(<HintMark>[VeilMark(holes)], hold: _ms(2400)),
    ]);
  }

  HintPlan tilesInTurn() =>
      HintPlan(<HintFrame>[for (int i = 0; i < _n; i++) HintFrame(const <HintMark>[], litOption: i)]);

  List<Rect> _questionParts() => <Rect>[
    if (a.group != null) ...(_groupRects(g, 0).isEmpty ? <Rect>[g.groupCell(0)] : _groupRects(g, 0)),
    if (a.group2 != null) ..._groupRects(g, 1),
    if (a.row.isNotEmpty) ...g.rowCells(),
    if (a.stageNumeral != null) g.stageNumeral,
  ];

  List<Rect> _groupRects(TapGeometry geo, int which) => geo.inReadingOrder(geo.groupObjects(which));

  /// The card for a second picture at the stage's end side, and the part of the stage it takes.
  Rect get _card => g.endCard;
  double get _reserve => g.endCard.right + 6;

  /// Where the tip of the finger that counts thing [i] (from 0) of [n] is drawn, when the hands of [n] stand in [card] (one hand
  /// up to five, two hands above): the card's padding and ring, then the hands centred and shrunk to fit, as [CardMark] draws them.
  Offset _fingerIn(Rect card, int i, int n) {
    const double handH = 84;
    final double handW = handH * HintHand.artSize.width / HintHand.artSize.height;
    final double w = n <= 5 ? handW : 2 * handW + 10;
    final Rect inner = card.deflate(6 * k + 3);
    final double f = math.min(1, math.min(inner.width / w, inner.height / handH));
    final Offset origin = inner.center - Offset(w * f / 2, handH * f / 2);
    final HandSide side = i < 5 ? HandSide.left : HandSide.right;
    final Offset tip = HintHand.tipInArt(side, i % 5) * (handH / HintHand.artSize.height);
    return origin + (Offset(i < 5 ? 0 : handW + 10, 0) + tip) * f;
  }

  /// Level 1 of a count: the things are lit one after the other, left to right, a dot staying on each; nothing is said or counted.
  List<HintFrame> _lightEach(
    List<Rect> rs, {
    bool round = true,
    List<HintMark> base = const <HintMark>[],
    double reserve = 0,
  }) => <HintFrame>[
    for (int i = 0; i < rs.length; i++)
      HintFrame(
        <HintMark>[...base, for (int j = 0; j < i; j++) SeenMark(rs[j]), RingMark(rs[i], round: round)],
        hold: _ms(950),
        reserve: reserve,
      ),
  ];

  // ---- a sample the child compares the options with (TA-6 colour, TA-7 shapes, TA-9 same) ----

  /// Level 2 shows the sample (a swatch, an outline, a copy of the model) in a sky card; level 3 glides it over each option in
  /// turn, and it stops on the one that matches. [make] draws the sample in a given box.
  HintPlan _sample(int level, HintMark Function(Rect box) make) {
    if (level == 1) return look();
    final bool beside = _questionParts().isNotEmpty;
    final Rect card = beside ? _card : g.centre(110 * k, 100 * k);
    final double side = math.min(66 * k, card.width - 16 * k);
    final Rect home = Rect.fromCenter(center: card.center, width: side, height: side);
    final double reserve = beside ? _reserve : 0;
    final List<HintMark> shown = <HintMark>[CardMark(card, const SizedBox.shrink()), make(home)];
    if (level == 2) {
      return HintPlan(
        <HintFrame>[HintFrame(shown, hold: _ms(2600), reserve: reserve)],
        rest: shown,
        restReserve: reserve,
      );
    }
    // The sample stands on the tile's top edge, just before the fingertip (the hand comes from the upper right), big enough to
    // be the same picture as in the card: 50 on a phone, at most 60 on a tablet.
    final double s = math.min(50 * k, 60);
    Rect above(int i) =>
        Rect.fromCenter(center: g.optionTip(i) - Offset(26 * k, s / 2 + 1), width: s, height: s);
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[make(home)], hold: _ms(700), reserve: reserve),
      for (int i = 0; i < _n; i++) HintFrame(<HintMark>[make(above(i))], hold: _ms(800), reserve: reserve),
      HintFrame(
        <HintMark>[make(above(_ci)), HandMark(g.optionTip(_ci), press: true)],
        hold: _ms(1300),
        reserve: reserve,
      ),
    ]);
  }

  /// A plan nothing in the activity can feed: look, a question mark card, and the hand along the options.
  HintPlan generic(int level) => switch (level) {
    1 => look(),
    2 => HintPlan(<HintFrame>[HintFrame(_questionCard, hold: _ms(2400))], rest: _questionCard),
    _ => _walkOptions(),
  };

  List<HintMark> get _questionCard => <HintMark>[
    CardMark(g.centre(80 * k, 80 * k), Text('?', style: AppText.fixed(size: 40, weight: 800, lineHeight: 1))),
  ];

  // ---- TA-6 colour ----

  HintPlan colour(int level) {
    final String? c = colourOfSprite(_spriteOf(_right)) ?? colourOfSprite(a.group?.sprite);
    if (c == null) return generic(level);
    if (level == 2 && _asksColourOfObject) return _emptyPaint();
    return _sample(level, (Rect box) => SwatchMark(box, c));
  }

  /// COL-A-05: a thing of the world on the stage ("which colour is the apple?") and plain colour balls to choose from. The paint of
  /// the right colour would be the answer, so level 2 never shows it.
  bool get _asksColourOfObject =>
      a.group != null && a.options.every((ChoiceOption o) => (o.sprite ?? '').startsWith('asset:ball_'));

  /// Level 2 of [_asksColourOfObject]: an empty paint spot (a dashed circle) beside the thing, "which paint is this one's?". It names
  /// no colour, and the child still has to find it among the tiles.
  HintPlan _emptyPaint() {
    final Rect card = _card;
    final double side = math.min(66 * k, card.width - 16 * k);
    final List<HintMark> shown = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      GhostMark(Rect.fromCenter(center: card.center, width: side, height: side), GhostKind.circle),
    ];
    return HintPlan(
      <HintFrame>[HintFrame(shown, hold: _ms(2600), reserve: _reserve)],
      rest: shown,
      restReserve: _reserve,
    );
  }

  // ---- TA-7 shapes ----

  HintPlan shapes(int level) {
    if (level == 1) return look();
    switch (a.skillId) {
      case 'SHP-A-07':
        return _solids(level);
      case 'SHP-A-08':
        return _position(level);
      default:
        final GhostKind? kind = _shapeKind();
        if (kind == null) return generic(level);
        return _sample(level, (Rect box) => GhostMark(box, kind, turn: a.skillId == 'SHP-A-03'));
    }
  }

  /// The shape the question asks for, read from the right option (`shape_circle_red`, a plate, `line_curved`).
  GhostKind? _shapeKind() {
    final String name = (_spriteOf(_right) ?? '').replaceFirst('asset:', '');
    if (name.startsWith('solid_')) {
      return switch (name.substring(6)) {
        'cylinder' => GhostKind.cylinder,
        'cone' => GhostKind.cone,
        'sphere' => GhostKind.circle,
        'pyramid' => GhostKind.pyramid,
        'box' => GhostKind.box,
        _ => null,
      };
    }
    if (a.skillId == 'SHP-A-10') {
      if (name.contains('curved') || name.contains('circle')) return GhostKind.curved;
      return GhostKind.straight;
    }
    if (name.contains('circle') || name == 'plate') return GhostKind.circle;
    if (name.contains('square')) return GhostKind.square;
    if (name.contains('rect') || name == 'window') return GhostKind.rect;
    if (name.contains('triangle') || name == 'sign') return GhostKind.triangle;
    return null;
  }

  /// SHP-A-07: two solids, a push or a stack. Both get the same treatment, and the property shows (the ball rolls away and the box
  /// stays; a second one stays on the box and slides off the ball). The question's own two things, no new ones; the question's
  /// word says whether it is about stacking.
  HintPlan _solids(int level) {
    final ChoiceOption? ball = _first((String s) => s.contains('sphere') || s.contains('ball'));
    final ChoiceOption? box = _first((String s) => s.contains('box'));
    if (_n != 2 || ball == null || box == null || _svg(ball.sprite) == null || _svg(box.sprite) == null) {
      return generic(level);
    }
    if (level == 3) return _walkOptions();
    final List<String> svgs = <String>[for (final ChoiceOption o in a.options) _svg(o.sprite)!];
    final bool isBall0 = identical(a.options[0], ball);
    final double side = 40 * k;
    final List<HintMark> end = _asksAbout(_stack)
        ? _stackScene(svgs, isBall0, side, landed: true)
        : _pushScene(svgs, isBall0, side, rolled: true);
    final List<HintMark> start = _asksAbout(_stack)
        ? _stackScene(svgs, isBall0, side, landed: false)
        : _pushScene(svgs, isBall0, side, rolled: false);
    return HintPlan(<HintFrame>[
      HintFrame(start, hold: _ms(900)),
      HintFrame(end, hold: _ms(2000)),
    ], rest: end);
  }

  /// Both solids in a lane of their own, each with the same push arrow; the ball has rolled away and the box has not moved.
  List<HintMark> _pushScene(List<String> svgs, bool isBall0, double side, {required bool rolled}) {
    Rect at(int lane, double x) =>
        Rect.fromCenter(center: Offset(x, g.h * (lane == 0 ? 0.3 : 0.72)), width: side, height: side);
    final double home = g.w * 0.16;
    final double far = g.w * 0.7;
    final List<Rect> where = <Rect>[
      at(0, rolled && isBall0 ? far : home),
      at(1, rolled && !isBall0 ? far : home),
    ];
    return <HintMark>[
      for (int i = 0; i < 2; i++)
        CopyMark(where[i], svgs[i], turns: rolled && (i == 0) == isBall0 ? 0.75 : 0),
      for (int i = 0; i < 2; i++)
        ArrowMark(
          Offset(home + side / 2 + 6 * k, at(i, home).center.dy),
          Offset(home + side / 2 + 32 * k, at(i, home).center.dy),
        ),
      if (rolled)
        LineMark(
          Offset(home + side / 2 + 40 * k, at(isBall0 ? 0 : 1, home).bottom + 4 * k),
          Offset(far - side / 2, at(isBall0 ? 0 : 1, home).bottom + 4 * k),
        ),
    ];
  }

  /// Both solids on one floor, and a second one of each: it is put on top and stays on the box, or slides off the ball.
  List<HintMark> _stackScene(List<String> svgs, bool isBall0, double side, {required bool landed}) {
    final double floor = g.h * 0.86;
    final double small = side * 0.6;
    final List<double> xs = <double>[g.w * 0.27, g.w * 0.7];
    return <HintMark>[
      for (int i = 0; i < 2; i++)
        CopyMark(Rect.fromLTWH(xs[i] - side / 2, floor - side, side, side), svgs[i]),
      for (int i = 0; i < 2; i++)
        CopyMark(
          landed && (i == 0) == isBall0
              ? Rect.fromLTWH(xs[i] + side * 0.62, floor - small, small, small)
              : Rect.fromLTWH(
                  xs[i] - small / 2,
                  landed ? floor - side - small : floor - side - small - 16 * k,
                  small,
                  small,
                ),
          svgs[i],
          turns: landed && (i == 0) == isBall0 ? 0.25 : 0,
        ),
      LineMark(Offset(g.w * 0.08, floor), Offset(g.w * 0.92, floor)),
    ];
  }

  ChoiceOption? _first(bool Function(String sprite) test) {
    for (final ChoiceOption o in a.options) {
      if (o.sprite != null && test(o.sprite!)) return o;
    }
    return null;
  }

  /// True when the question (without vowel marks) has [word] in it, with or without a prefix letter ("to the table").
  bool _asksAbout(String word) => _plain(a.promptLine.caption).contains(word);

  /// SHP-A-08: the position of the question's word acted out in a sky card with a small toy and the thing the question names (a
  /// box, or the table of "under the table"). Only the relation is the tile's: the tiles show a red ball, so the toy is another
  /// figure, and the drawing of the box is not the tile's.
  HintPlan _position(int level) {
    final String where = (_right.sprite ?? '').replaceFirst('asset:pos_', '');
    final String? toy = _svg('asset:duck');
    if (toy == null || !<String>{'above', 'on', 'next', 'under', 'in'}.contains(where)) return generic(level);
    if (level == 3) return _walkOptions();
    // The thing, and where its drawn top and its drawn foot are in its picture's box (parts of the box).
    final ({String svg, double top, double foot}) shape = _asksAbout(_table)
        ? (svg: _tableSvg, top: 0.18, foot: 0.96)
        : (where == 'in' ? (svg: _binSvg, top: 0.40, foot: 0.92) : (svg: _boxSvg, top: 0.22, foot: 0.92));
    final Rect card = g.centre(150 * k, 112 * k);
    final double b = 52 * k;
    final double d = 30 * k;
    final Offset c = card.center;
    Rect thing(double dx, double dy) =>
        Rect.fromCenter(center: c + Offset(dx * k, dy * k), width: b, height: b);
    Rect small(double x, double y) => Rect.fromCenter(center: Offset(x, y), width: d, height: d);
    double top(Rect o) => o.top + shape.top * b;
    double foot(Rect o) => o.top + shape.foot * b;
    final Rect o;
    final Rect t;
    switch (where) {
      case 'above':
        o = thing(0, 24);
        t = small(c.dx, top(o) - 16 * k - d / 2);
      case 'on':
        o = thing(0, 18);
        t = small(c.dx, top(o) - d / 2 + 1);
      case 'next':
        o = thing(-28, 8);
        t = small(c.dx + 36 * k, foot(o) - d / 2);
      case 'under':
        o = thing(0, 0);
        t = small(c.dx, foot(o) - d / 2 - 1);
      default:
        o = thing(0, 14);
        t = small(c.dx, top(o) - d * 0.1);
    }
    final List<HintMark> scene = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      // Something that holds the toy is drawn over it; anything else is drawn first.
      if (where == 'in') ...<HintMark>[CopyMark(t, toy), CopyMark(o, shape.svg)] else ...<HintMark>[
        CopyMark(o, shape.svg),
        CopyMark(t, toy),
      ],
    ];
    return HintPlan(<HintFrame>[HintFrame(scene, hold: _ms(2600))], rest: scene);
  }

  // ---- TA-4 compare ----

  /// The two groups to compare: the sets of the two options (drawn on the tiles) or the two groups of the stage.
  HintPlan compare(int level) {
    final bool onStage = a.group != null && a.group2 != null;
    final List<(String, int)> sets = <(String, int)>[
      if (!onStage)
        for (final ChoiceOption o in a.options)
          if (o.set != null && _svg(o.set!.sprite) != null) (_svg(o.set!.sprite)!, o.set!.count),
    ];
    if (!onStage && sets.length != 2) return generic(level);

    List<Rect> top;
    List<Rect> bottom;
    List<HintMark> copies = <HintMark>[];
    // The copies of the two tiles' sets, one at a time (the first option's row on top): they come up from their own tile, so a row
    // is known by the tile it came from. Each row keeps a thin connector to that tile once it has landed.
    final List<HintFrame> flight = <HintFrame>[];
    if (onStage) {
      top = _groupRects(g, 0);
      bottom = _groupRects(g, 1);
      // The groups already stand side by side: the pairs are drawn between them.
    } else {
      // Equal size and equal spacing in two rows from the start line: the size and the crowding of the tiles are gone (P8).
      final int most = math.max(sets[0].$2, sets[1].$2);
      final double d = math.min(math.min(36 * k, (g.w - 70 * k) / math.max(most, 1)), g.h * 0.32);
      final double step = d * 1.25;
      List<Rect> row(int count, double y) => <Rect>[
        for (int i = 0; i < count; i++)
          Rect.fromCenter(center: Offset(40 * k + i * step, y), width: d, height: d),
      ];
      top = row(sets[0].$2, g.h * 0.3);
      bottom = row(sets[1].$2, g.h * 0.72);
      // Under its tile (the tile paints over the stage), so a set rises out of the tile's top edge.
      List<Rect> underTile(int tile, int count) => <Rect>[
        for (int i = 0; i < count; i++)
          Rect.fromCenter(center: g.optionTip(tile) + Offset(0, d / 2 + 8 * k), width: d, height: d),
      ];
      final Offset startLineTop = Offset(24 * k, 6 * k);
      final HintMark startLine = LineMark(startLineTop, Offset(24 * k, g.h - 6 * k));
      HintMark connector(int tile, Rect firstOfRow) =>
          LineMark(Offset(24 * k, firstOfRow.center.dy), g.optionTip(tile) - Offset(0, 3 * k), faint: true);
      List<HintMark> pictures(List<Rect> a, List<Rect> b) => <HintMark>[
        for (final Rect r in a) CopyMark(r, sets[0].$1),
        for (final Rect r in b) CopyMark(r, sets[1].$1),
      ];
      final List<Rect> home0 = underTile(0, top.length);
      final List<Rect> home1 = underTile(1, bottom.length);
      flight.addAll(<HintFrame>[
        HintFrame(pictures(home0, home1), hold: _ms(200)),
        HintFrame(<HintMark>[...pictures(top, home1), startLine, connector(0, top.first)], hold: _ms(900)),
      ]);
      copies = <HintMark>[
        ...pictures(top, bottom),
        startLine,
        connector(0, top.first),
        connector(1, bottom.first),
      ];
    }
    final int pairs = math.min(top.length, bottom.length);
    final List<Rect> left = top.length > bottom.length ? top.sublist(pairs) : <Rect>[];
    final List<Rect> leftB = bottom.length > top.length ? bottom.sublist(pairs) : <Rect>[];
    final List<Rect> leftover = <Rect>[...left, ...leftB];
    List<(Offset, Offset)> lines(int upTo) => <(Offset, Offset)>[
      for (int i = 0; i < upTo; i++) (top[i].center, bottom[i].center),
    ];
    if (level == 1) {
      if (onStage) return look();
      return HintPlan(<HintFrame>[...flight, HintFrame(copies, hold: _ms(2000))], rest: copies);
    }
    if (level == 2) {
      final List<HintFrame> frames = <HintFrame>[
        for (int i = 1; i <= pairs; i++)
          HintFrame(<HintMark>[...copies, PairsMark(lines: lines(i))], hold: _ms(550)),
        HintFrame(<HintMark>[...copies, PairsMark(lines: lines(pairs), unpaired: leftover)], hold: _ms(1800)),
      ];
      return HintPlan(
        frames,
        rest: <HintMark>[
          ...copies,
          PairsMark(lines: lines(pairs), unpaired: leftover),
        ],
      );
    }
    return _demo(<HintFrame>[
      HintFrame(copies, hold: _ms(600)),
      for (int i = 1; i <= pairs; i++)
        HintFrame(<HintMark>[
          ...copies,
          PairsMark(lines: lines(i)),
          HandMark((top[i - 1].center + bottom[i - 1].center) / 2, press: true),
        ], hold: _ms(700)),
      for (int j = 1; j <= leftover.length; j++)
        HintFrame(<HintMark>[
          ...copies,
          PairsMark(lines: lines(pairs), unpaired: leftover),
          for (int q = 1; q <= j; q++) BadgeMark(leftover[q - 1].topRight, q),
          HandMark(leftover[j - 1].center, press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[...copies, PairsMark(lines: lines(pairs), unpaired: leftover)]),
    ]);
  }

  // ---- TA-1 count a group ----

  HintPlan count(int level) {
    if (a.row.isNotEmpty) return _steps(level);
    if (a.group == null) return generic(level);
    if (_right.numeral == 0) return _zero(level);
    final TapGeometry g2 = g.withReserve(_reserve);
    final List<Rect> objs = _groupRects(level == 1 ? g : g2, 0);
    final int n = objs.length;
    if (n == 0) return generic(level);
    if (level == 1) {
      return HintPlan(_lightEach(objs), rest: <HintMark>[for (final Rect r in objs) SeenMark(r)]);
    }
    Widget hands(int raised) => raised <= 5
        ? HintHand(fingers: raised, side: HandSide.left, height: 84)
        : CountingHands(raised: raised);
    if (level == 2) {
      // Each thing keeps a dotted line to the hand (mockup M2), so the hand reads as the same things counted another way. The lines
      // aim at their own fingers but pass under the card, so they end on its edge and never cross the drawn fingers.
      List<HintMark> links(int upTo) => <HintMark>[
        for (int j = 0; j < upTo; j++) LineMark(objs[j].center, _fingerIn(_card, j, n)),
      ];
      final List<HintFrame> frames = <HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(0))], hold: _ms(500), reserve: _reserve),
        for (int i = 0; i < n; i++)
          HintFrame(
            <HintMark>[
              ...links(i + 1),
              CardMark(_card, hands(i + 1)),
              for (int j = 0; j < i; j++) SeenMark(objs[j]),
              RingMark(objs[i]),
            ],
            hold: _ms(950),
            reserve: _reserve,
          ),
      ];
      return HintPlan(
        frames,
        rest: <HintMark>[...links(n), CardMark(_card, hands(n)), for (final Rect r in objs) SeenMark(r)],
        restReserve: _reserve,
      );
    }
    List<HintMark> badges(int upTo) => <HintMark>[
      for (int j = 0; j < upTo; j++) BadgeMark(objs[j].topRight, j + 1),
    ];
    final List<HintMark> counted = <HintMark>[...badges(n), BadgeMark(_card.center, n, big: true)];
    return _demo(<HintFrame>[
      HintFrame(const <HintMark>[], hold: _ms(500), reserve: _reserve),
      for (int i = 0; i < n; i++)
        HintFrame(
          <HintMark>[...badges(i + 1), HandMark(objs[i].center, press: true)],
          hold: _ms(850),
          reserve: _reserve,
        ),
      HintFrame(<HintMark>[...counted, HandMark(objs[n - 1].center)], hold: _ms(900), reserve: _reserve),
      _toAnswer(counted, reserve: _reserve),
    ]);
  }

  /// Zero (NUM-A-14): nothing is there, so the hand runs over an empty ten-frame and finds nothing to count.
  HintPlan _zero(int level) {
    if (level == 1) {
      final List<Rect> objs = _groupRects(g, 0);
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(objs.isEmpty ? <Rect>[g.groupCell(0)] : objs),
        ], hold: _ms(2400)),
      ]);
    }
    final Rect card = g.centre(170 * k, 92 * k);
    final List<HintMark> frame = <HintMark>[CardMark(card, const TenFrames(total: 10, filled: 0))];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(frame, hold: _ms(2600))], rest: frame);
    final List<Offset> cells = <Offset>[
      card.center + Offset(-44 * k, -10 * k),
      card.center + Offset(44 * k, -10 * k),
      card.center + Offset(-44 * k, 14 * k),
      card.center + Offset(44 * k, 14 * k),
    ];
    return _demo(<HintFrame>[
      for (final Offset c in cells) HintFrame(<HintMark>[...frame, HandMark(c, press: true)], hold: _ms(700)),
      _toAnswer(<HintMark>[...frame, BadgeMark(card.center + Offset(0, -2 * k), 0, big: true)]),
    ]);
  }

  /// CS-A-04: the steps from the robot to the flag are the hops between the squares of the row.
  HintPlan _steps(int level) {
    final List<Rect> cells = g.rowCells();
    final int hops = cells.length - 1;
    Offset top(int i) => Offset(cells[i].center.dx, cells[i].top + 4 * k);
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[cells.first, cells.last]),
        ], hold: _ms(2400)),
      ]);
    }
    List<HintMark> arcs(int upTo) => <HintMark>[for (int i = 0; i < upTo; i++) ArcMark(top(i), top(i + 1))];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i <= hops; i++) HintFrame(arcs(i), hold: _ms(800)),
      ], rest: arcs(hops));
    }
    return _demo(<HintFrame>[
      for (int i = 1; i <= hops; i++)
        HintFrame(<HintMark>[
          ...arcs(i),
          for (int j = 1; j <= i; j++) BadgeMark(top(j) + Offset(0, -10 * k), j),
          HandMark(top(i), press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[
        ...arcs(hops),
        for (int j = 1; j <= hops; j++) BadgeMark(top(j) + Offset(0, -10 * k), j),
      ]),
    ]);
  }

  // ---- TA-3 sequence ----

  /// The number the question gives, from the answer [c]: the one before it when the question asks what comes after (or adds one), the
  /// one after it when it asks what comes before (or takes one away); in a row, the number left of the gap. Null when it cannot tell.
  int? _givenFor(int c) {
    final String q = _plain(a.promptLine.caption);
    if (a.row.isNotEmpty) {
      final int gap = a.row.indexOf('?');
      final String? side = gap > 0 ? a.row[gap - 1] : (gap == 0 && a.row.length > 1 ? a.row[1] : null);
      final int? known = side != null && side.startsWith('n:') ? int.tryParse(side.substring(2)) : null;
      return known;
    }
    final bool takes = a.skillId == 'NUM-B-11' && q.contains(_from);
    final bool before = q.contains(_before) || takes;
    final bool after = q.contains(_after) || (a.skillId == 'NUM-B-11' && !takes);
    if (!before && !after) return null;
    return before ? c + 1 : c - 1;
  }

  HintPlan sequence(int level) {
    if (a.skillId == 'NUM-A-13') return _ordinal(level);
    if (a.skillId == 'NUM-B-17') return _skipCount(level);
    final int? c = _right.numeral;
    final int? given = c == null ? null : _givenFor(c);
    if (c == null || given == null) return generic(level);
    final bool before = given > c;
    final bool bandB = a.skillId.contains('-B-');
    // Band A counts from 1 on a path of five or ten squares; Band B shows ten squares around the two numbers.
    final int m = bandB || given > 5 || c > 5 || a.options.any((ChoiceOption o) => (o.numeral ?? 0) > 5)
        ? 10
        : 5;
    final int from = bandB ? math.max(1, math.min(given, c) - 4) : 1;
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, m * 30 * k),
      height: 36 * k,
    );
    Offset squareTop(int n) => Offset(path.left + (n - from + 0.5) * path.width / m, path.top + 2 * k);
    if (level == 1) {
      if (a.row.isNotEmpty) return look();
      // The number we are given and an empty place next to it, left to right: the gap is where to look (the question, no answer).
      final double s = 52 * k;
      final Rect givenAt = Rect.fromCenter(
        center: Offset(g.w / 2 + (before ? 34 : -34) * k, g.h / 2),
        width: s,
        height: s,
      );
      final Rect gapAt = Rect.fromCenter(
        center: Offset(g.w / 2 + (before ? -34 : 34) * k, g.h / 2),
        width: s,
        height: s,
      );
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[givenAt, gapAt]),
          CardMark(givenAt, Text('$given', style: AppText.fixed(size: 30, weight: 800, lineHeight: 1))),
          GhostMark(gapAt, GhostKind.square),
        ], hold: _ms(2600)),
      ]);
    }
    PathMark strip({int? marker, int? gap, int? ring}) =>
        PathMark(rect: path, count: m, gap: gap, ring: ring, marker: marker, from: from);
    if (level == 2) {
      final List<HintMark> shown = <HintMark>[strip(gap: c, ring: given)];
      return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    }
    if (bandB) {
      // The marker stands on the number given, hops one square (to the right, or back to the left) and lands in the place.
      final ArcMark hop = ArcMark(squareTop(given), squareTop(c));
      return _demo(<HintFrame>[
        HintFrame(<HintMark>[
          strip(gap: c, marker: given),
          HandMark(squareTop(given), press: true),
        ], hold: _ms(900)),
        HintFrame(<HintMark>[
          strip(gap: c, marker: given),
          hop,
          HandMark(squareTop(c), press: true),
        ], hold: _ms(900)),
        HintFrame(<HintMark>[strip(marker: c), hop, HandMark(squareTop(c))], hold: _ms(900)),
        _toAnswer(<HintMark>[strip(marker: c), hop]),
      ]);
    }
    return _demo(<HintFrame>[
      for (int j = 1; j <= c; j++)
        HintFrame(<HintMark>[strip(gap: c, marker: j), HandMark(squareTop(j), press: true)], hold: _ms(620)),
      _toAnswer(<HintMark>[strip(marker: c)]),
    ]);
  }

  /// NUM-A-13: first, second, third, last. The tiles are the queue and its front is the first tile of the row (the right-hand one:
  /// the row of tiles runs right to left), so nothing is drawn in the stage that could read as a number line. Each tile gets a place
  /// badge over its top edge, 1 at the front, and a small start flag stands at the front's end (the tiles draw both: they paint
  /// above the speech bubble). Level 3: the hand walks the tiles from the front and stops on the right one.
  HintPlan _ordinal(int level) {
    if (level == 1) return tilesInTurn();
    List<HintMark> shown(int upTo) => <HintMark>[
      const TileFlagMark(0),
      for (int j = 0; j < upTo; j++) TileBadgeMark(j, j + 1),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int j = 1; j <= _n; j++) HintFrame(shown(j), hold: _ms(700)),
      ], rest: shown(_n));
    }
    return _demo(<HintFrame>[
      HintFrame(shown(0), hold: _ms(600)),
      for (int i = 0; i < _ci; i++)
        HintFrame(<HintMark>[...shown(i + 1), HandMark(g.optionTip(i), press: true)], hold: _ms(850)),
      _toAnswer(shown(_ci + 1)),
    ]);
  }

  // ---- TA-8 pattern rows, TA-10 order in time ----

  HintPlan pattern(int level) {
    if (a.row.isEmpty) return generic(level);
    final List<Rect> cells = g.rowCells();
    final int gap = a.row.indexOf('?');
    final List<HintMark> seen = <HintMark>[
      for (int i = 0; i < cells.length; i++)
        if (i != gap) SeenMark(cells[i]),
    ];
    if (level == 1) return HintPlan(_lightEach(cells, round: false), rest: seen);
    final bool yesNo = a.options.every(
      (ChoiceOption o) => o.sprite == 'asset:tick' || o.sprite == 'asset:cross',
    );
    final int? p = periodOf(a.row);
    final double y = cells.first.bottom + 8 * k;
    List<HintMark> brackets(int upTo) {
      final int size = p ?? (yesNo ? cells.length ~/ 2 : 0);
      if (size == 0) return <HintMark>[];
      final List<HintMark> out = <HintMark>[];
      for (int b = 0; b < upTo; b++) {
        final int from = b * size;
        final int to = math.min(cells.length, from + size) - 1;
        if (from > to) break;
        out.add(BracketMark(Offset(cells[from].left + 2 * k, y), Offset(cells[to].right - 2 * k, y)));
      }
      return out;
    }

    final int blocks = p == null && !yesNo ? 0 : (cells.length / (p ?? cells.length ~/ 2)).ceil();
    if (level == 2) {
      if (blocks == 0) {
        // A row that grows (seriation): one floor under every cell, and the neighbours are linked. A row of towers (LOG-B-04) also
        // has the number of cubes of each step under it, but not under the empty place.
        final List<HintMark> floor = <HintMark>[
          LineMark(Offset(cells.first.left, y), Offset(cells.last.right, y)),
          if (a.skillId == 'LOG-B-04')
            for (int i = 0; i < cells.length; i++)
              if (i != gap) ?_towerHeight(a.row[i], cells[i].center.dx, y + 14 * k),
          for (int i = 0; i + 1 < cells.length; i++)
            ArcMark(
              Offset(cells[i].center.dx, cells[i].top),
              Offset(cells[i + 1].center.dx, cells[i + 1].top),
            ),
        ];
        return HintPlan(<HintFrame>[HintFrame(floor, hold: _ms(2800))], rest: floor);
      }
      return HintPlan(<HintFrame>[
        for (int b = 1; b <= blocks; b++) HintFrame(brackets(b), hold: _ms(900)),
      ], rest: brackets(blocks));
    }
    return _rowDemo(cells, gap);
  }

  /// The number of cubes of a tower picture (`tower_3`) as a badge under it, or null for a picture that is not a tower.
  HintMark? _towerHeight(String ref, double x, double y) {
    final RegExpMatch? m = RegExp(r'tower_(\d+)$').firstMatch(ref);
    return m == null ? null : BadgeMark(Offset(x, y), int.parse(m[1]!));
  }

  /// The hand reads the row from the left, and where there is a gap the right picture appears in it last.
  HintPlan _rowDemo(List<Rect> cells, int gap, {List<HintMark> base = const <HintMark>[]}) {
    final String? answerSvg = gap >= 0 ? _svg(_spriteOf(_right)) : null;
    final List<HintMark> filled = <HintMark>[
      ...base,
      // The picture covers the "?" of the empty place: it stands on a card of the place's size.
      if (answerSvg != null) CopyMark(cells[gap], answerSvg, backed: true),
    ];
    return _demo(<HintFrame>[
      for (int i = 0; i < cells.length; i++)
        HintFrame(<HintMark>[...base, HandMark(cells[i].center, press: true)], hold: _ms(620)),
      HintFrame(<HintMark>[...filled, if (gap >= 0) HandMark(cells[gap].center)], hold: _ms(900)),
      _toAnswer(filled),
    ]);
  }

  HintPlan time(int level) {
    if (a.row.isNotEmpty) {
      final List<Rect> cells = g.rowCells();
      final int gap = a.row.indexOf('?');
      if (level == 1) {
        return HintPlan(<HintFrame>[
          HintFrame(<HintMark>[
            VeilMark(<Rect>[cells.first]),
          ], hold: _ms(2400)),
        ]);
      }
      final List<HintMark> numbers = <HintMark>[
        for (int i = 0; i < cells.length; i++)
          BadgeMark(Offset(cells[i].center.dx, cells[i].bottom + 12 * k), i + 1),
      ];
      if (level == 2) {
        return HintPlan(<HintFrame>[
          for (int i = 1; i <= cells.length; i++) HintFrame(numbers.sublist(0, i), hold: _ms(800)),
        ], rest: numbers);
      }
      return _rowDemo(cells, gap, base: numbers);
    }
    if (level == 1) return tilesInTurn();
    // The steps of the story are numbered places in a row, left to right.
    final Rect slots = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2),
      width: math.min(g.w - 20, _n * 56 * k),
      height: 52 * k,
    );
    final List<HintMark> shown = <HintMark>[PathMark(rect: slots, count: _n)];
    if (level == 2) return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    Offset slotTop(int j) => Offset(slots.left + (j - 0.5) * slots.width / _n, slots.top + 2 * k);
    return _demo(<HintFrame>[
      for (int j = 1; j <= _n; j++)
        HintFrame(<HintMark>[
          PathMark(rect: slots, count: _n, marker: j),
          HandMark(slotTop(j), press: true),
        ], hold: _ms(800)),
      _toAnswer(shown),
    ]);
  }

  // ---- TA-9 same, odd one out ----

  HintPlan same(int level) {
    if (a.row.isNotEmpty) return _oddOne(level);
    final String? model = _svg(a.group?.sprite);
    if (model == null) return generic(level);
    return _sample(level, (Rect box) => CopyMark(box, model));
  }

  /// LOG-A-02: four in a row, one is different. Level 2 links each to the next, level 3 walks along and stops on the odd one.
  HintPlan _oddOne(int level) {
    final List<Rect> cells = g.rowCells();
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[VeilMark(cells)], hold: _ms(2400)),
      ]);
    }
    List<HintMark> links(int upTo) => <HintMark>[
      for (int i = 0; i < upTo; i++)
        ArcMark(Offset(cells[i].center.dx, cells[i].top), Offset(cells[i + 1].center.dx, cells[i + 1].top)),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int i = 1; i < cells.length; i++) HintFrame(links(i), hold: _ms(800)),
      ], rest: links(cells.length - 1));
    }
    // The odd one is the cell whose picture is not the commonest.
    final Map<String, int> seen = <String, int>{};
    for (final String r in a.row) {
      seen[r] = (seen[r] ?? 0) + 1;
    }
    final int odd = a.row.indexWhere((String r) => seen[r] == 1);
    final int stop = odd < 0 ? cells.length - 1 : odd;
    return _demo(<HintFrame>[
      for (int i = 0; i <= stop; i++)
        HintFrame(<HintMark>[HandMark(cells[i].center, press: true)], hold: _ms(700)),
      HintFrame(<HintMark>[
        RingMark(cells[stop], round: false),
        HandMark(cells[stop].center),
      ], hold: _ms(900)),
      _toAnswer(<HintMark>[RingMark(cells[stop], round: false)]),
    ]);
  }

  // ---- TA-5 add, take away ----

  HintPlan add(int level) {
    if (a.group == null) return generic(level);
    final TapGeometry g2 = g.withReserve(_reserve);
    final List<Rect> first = _groupRects(level == 1 ? g : g2, 0);
    final List<Rect> second = a.group2 != null ? _groupRects(level == 1 ? g : g2, 1) : <Rect>[];
    final bool adds = a.group2 != null;
    final int total = _right.numeral ?? first.length;
    final int start = first.length;
    if (level == 1) {
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[VeilMark(first)], hold: _ms(1500)),
        if (adds) HintFrame(<HintMark>[VeilMark(second)], hold: _ms(1500)),
      ]);
    }
    // Up to ten a number is shown as hands; above ten (Band B) the card holds the numeral.
    Widget hands(int raised) => raised > 10
        ? Text('$raised', style: AppText.fixed(size: 44, weight: 800, lineHeight: 1))
        : (raised <= 5
              ? HintHand(fingers: math.max(0, raised), side: HandSide.left, height: 84)
              : CountingHands(raised: raised));
    if (adds) {
      // Count on: the hand shows the first group, and the second group is counted one by one on top of it.
      final int more = second.length;
      // "How many more?" (the answer is the second group) counts that group from one; "how many in all" counts on from the first.
      final bool asksMore = total == more && total != start + more;
      List<HintMark> done(int j) => <HintMark>[
        for (final Rect r in first) SeenMark(r),
        for (int i = 0; i < j; i++) SeenMark(second[i]),
      ];
      if (level == 2) {
        final List<HintFrame> frames = <HintFrame>[
          HintFrame(<HintMark>[CardMark(_card, hands(start)), ...done(0)], hold: _ms(900), reserve: _reserve),
          for (int j = 0; j < more; j++)
            HintFrame(
              <HintMark>[CardMark(_card, hands(start)), ...done(j), RingMark(second[j])],
              hold: _ms(900),
              reserve: _reserve,
            ),
        ];
        return HintPlan(
          frames,
          rest: <HintMark>[CardMark(_card, hands(start)), ...done(more)],
          restReserve: _reserve,
        );
      }
      return _demo(<HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(start)), ...done(0)], hold: _ms(800), reserve: _reserve),
        for (int j = 1; j <= more; j++)
          HintFrame(
            <HintMark>[
              CardMark(_card, hands(asksMore ? start : start + j)),
              ...done(j),
              BadgeMark(second[j - 1].topRight, asksMore ? j : start + j),
              HandMark(second[j - 1].center, press: true),
            ],
            hold: _ms(more > 6 ? 600 : 900),
            reserve: _reserve,
          ),
        // The count card takes the hand card's place (drawn over it, the hand peeked out above the number).
        _toAnswer(<HintMark>[...done(more), BadgeMark(_card.center, total, big: true)], reserve: _reserve),
      ]);
    }
    // Take away: the hand shows the group, and the things taken away fold a finger each.
    final int taken = math.max(0, first.length - total);
    final List<Rect> gone = first.length >= taken ? first.sublist(first.length - taken) : <Rect>[];
    if (level == 2) {
      final List<HintFrame> frames = <HintFrame>[
        HintFrame(<HintMark>[CardMark(_card, hands(start))], hold: _ms(900), reserve: _reserve),
        for (int j = 0; j < gone.length; j++)
          HintFrame(
            <HintMark>[CardMark(_card, hands(start)), RingMark(gone[gone.length - 1 - j])],
            hold: _ms(900),
            reserve: _reserve,
          ),
      ];
      return HintPlan(frames, rest: <HintMark>[CardMark(_card, hands(start))], restReserve: _reserve);
    }
    return _demo(<HintFrame>[
      HintFrame(<HintMark>[CardMark(_card, hands(start))], hold: _ms(800), reserve: _reserve),
      for (int j = 1; j <= gone.length; j++)
        HintFrame(
          <HintMark>[CardMark(_card, hands(start - j)), HandMark(gone[gone.length - j].center, press: true)],
          hold: _ms(900),
          reserve: _reserve,
        ),
      _toAnswer(<HintMark>[BadgeMark(_card.center, total, big: true)], reserve: _reserve),
    ]);
  }

  // ---- TA-2 numerals ----

  HintPlan numerals(int level) {
    final int? n = a.stageNumeral ?? _right.numeral;
    if (n == null || n < 1) return generic(level);
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, 5 * 40 * k),
      height: 40 * k,
    );
    Offset squareTop(int j) => Offset(path.left + (j - 0.5) * path.width / 5, path.top + 2 * k);
    final String? sprite = _svg(_spriteOf(_right));
    if (level == 1) {
      if (a.stageNumeral == null) return tilesInTurn();
      final Rect dots = Rect.fromCenter(
        center: Offset(g.w / 2 + g.h * 0.55 + 20 * k, g.h / 2),
        width: math.min(g.w * 0.25, (n * 12 + 16) * k),
        height: 30 * k,
      );
      return HintPlan(<HintFrame>[
        HintFrame(<HintMark>[
          VeilMark(<Rect>[g.stageNumeral, dots]),
          CardMark(dots, Dots(n)),
        ], hold: _ms(2600)),
      ]);
    }
    // Over the numeral of the stage (when there is one) a sky card holds the number path: 1 to 5, a marker walking to the number.
    final Rect cover = Rect.fromCenter(
      center: path.center.translate(0, -6 * k),
      width: path.width + 14 * k,
      height: g.h * 0.8,
    );
    List<HintMark> strip({int? marker}) => <HintMark>[
      if (a.stageNumeral != null) CardMark(cover, const SizedBox.shrink()),
      PathMark(rect: path, count: 5, ring: marker == n ? n : null, marker: marker),
    ];
    if (level == 2) {
      return HintPlan(<HintFrame>[
        for (int j = 1; j <= n; j++) HintFrame(strip(marker: j), hold: _ms(700)),
      ], rest: strip(marker: n));
    }
    if (a.stageNumeral == null || sprite == null) {
      return _demo(<HintFrame>[
        for (int j = 1; j <= n; j++)
          HintFrame(<HintMark>[...strip(marker: j), HandMark(squareTop(j), press: true)], hold: _ms(700)),
        _toAnswer(strip(marker: n)),
      ]);
    }
    // The quantity is built on the stage, one by one, and then the hand goes to the set that matches.
    final double d = math.min(38 * k, (g.w - 50) / n);
    Rect at(int i) =>
        Rect.fromCenter(center: Offset(g.w / 2 + (i - (n - 1) / 2) * d * 1.2, g.h / 2), width: d, height: d);
    List<HintMark> built(int upTo) => <HintMark>[
      CardMark(g.centre(math.min(g.w - 20, (n * 1.2 + 0.6) * d), g.h * 0.8), const SizedBox.shrink()),
      for (int i = 0; i < upTo; i++) ...<HintMark>[CopyMark(at(i), sprite), BadgeMark(at(i).topRight, i + 1)],
    ];
    return _demo(<HintFrame>[
      for (int i = 1; i <= n; i++)
        HintFrame(<HintMark>[...built(i), HandMark(at(i - 1).center, press: true)], hold: _ms(800)),
      _toAnswer(built(n)),
    ]);
  }

  // ---- TA-11 measure ----

  /// The ink box with room for the outline (the pack pictures' strokes are about 3 in a box of 100).
  static Rect _withStroke(Rect ink) => Rect.fromLTRB(
    math.max(0, ink.left - 0.015),
    math.max(0, ink.top - 0.015),
    math.min(1, ink.right + 0.015),
    math.min(1, ink.bottom + 0.015),
  );

  HintPlan measure(int level) {
    // Heavy and light are not seen with a stick of cubes: they wait for the seesaw (P10), and the generic ladder serves until then.
    final Set<String> asked = _wordsOf(a.promptLine.caption);
    if (asked.contains(_heavy) || asked.contains(_light)) return generic(level);
    final List<(String, double, Rect)> things = <(String, double, Rect)>[
      for (final ChoiceOption o in a.options)
        if (_svg(_spriteOf(o)) != null)
          (_svg(_spriteOf(o))!, o.set?.scale ?? 1, _withStroke(inkBoxOf(_svg(_spriteOf(o))!))),
    ];
    if (things.length != 2) return generic(level);
    // Both things are drawn at one scale (the scale of a set kept), each in its own half of the stage, its drawn end on the
    // start line: what a child compares is the ink, not the picture's box (a short stick is drawn in the middle of its box).
    // The cubes are as big as the things let them be (at most 22 on a phone, so that a long stick is about eight cubes, each
    // big enough to count); the room left for a thing is planned with the biggest cube.
    const double most = 22;
    final double startX = 30 * k;
    final double left = startX + 4 * k;
    final double band = g.h / 2;
    final double roomH = band - most * k - 10 * k;
    final double roomW = g.w - left - 24 * k;
    double widest = 0;
    double tallest = 0;
    for (final (String _, double s, Rect ink) in things) {
      widest = math.max(widest, ink.width * s);
      tallest = math.max(tallest, ink.height * s);
    }
    double side = math.min(210 * k, math.min(roomW / widest, roomH / tallest));
    final List<Rect> drawn = <Rect>[];
    final List<Rect> ink = <Rect>[];
    // A picture's box (bigger than its ink) must stay on the stage too: a little smaller until it does.
    for (int tries = 0; tries < 40; tries++) {
      drawn.clear();
      ink.clear();
      for (int i = 0; i < 2; i++) {
        final (String _, double s, Rect box) = things[i];
        final double d = side * s;
        final double inkH = box.height * d;
        final double top = i * band + 4 * k + (roomH - inkH) / 2;
        ink.add(Rect.fromLTWH(left, top, box.width * d, inkH));
        // The copy is cut to its ink (see [cropToInk]), so its box is the ink itself.
        drawn.add(ink.last);
      }
      if (drawn.every((Rect r) => r.left >= 0 && r.top >= 0 && r.right <= g.w && r.bottom <= g.h)) break;
      side *= 0.95;
    }
    final double cube = (math.max(ink[0].width, ink[1].width) / 8).clamp(14 * k, most * k).toDouble();
    final List<HintMark> aligned = <HintMark>[
      LineMark(Offset(startX, 6 * k), Offset(startX, g.h - 6 * k)),
      for (int i = 0; i < 2; i++) CopyMark(drawn[i], cropToInk(things[i].$1, things[i].$3)),
    ];
    if (level == 1) return HintPlan(<HintFrame>[HintFrame(aligned, hold: _ms(2600))], rest: aligned);
    if (level == 2) {
      // A stick of cubes along each, from the same start line: the longer has more.
      final List<HintMark> cubes = <HintMark>[
        for (final Rect r in ink)
          for (int c = 0; c < math.max(1, (r.width / cube).round()); c++)
            BlockMark(Rect.fromLTWH(left + c * cube, r.bottom + 3 * k, cube - 2 * k, cube - 2 * k)),
      ];
      return HintPlan(
        <HintFrame>[
          HintFrame(<HintMark>[...aligned, ...cubes], hold: _ms(2800)),
        ],
        rest: <HintMark>[...aligned, ...cubes],
      );
    }
    return _walkOptions(base: aligned);
  }
}
