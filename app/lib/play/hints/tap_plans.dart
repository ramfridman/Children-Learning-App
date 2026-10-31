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
import 'tap_geometry.dart';

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
  if (family == null || !HintLadder.tapFamiliesBuilt.contains(family)) return null;
  final _Plans p = _Plans(a, g);
  final int l = level.clamp(1, 3);
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
  };
}

/// The colour a sprite name ends in (`ball_red`, `shape_circle_yellow`), or null.
String? colourOfSprite(String? ref) {
  if (ref == null) return null;
  final String last = ref.split('_').last;
  return hintColours.containsKey(last) ? last : null;
}

/// The words of a number question that say which way the sequence goes, written as code points (every Hebrew string of the app
/// lives in `strings/he.dart`; these two are read, never shown): "before" and "after".
final String _before = String.fromCharCodes(<int>[0x5DC, 0x5E4, 0x5E0, 0x5D9]);
final String _after = String.fromCharCodes(<int>[0x5D0, 0x5D7, 0x5E8, 0x5D9]);

/// The Hebrew text of a prompt without its vowel marks, to look for one word.
String _plain(String s) => s.replaceAll(_vowelMarks, '');

final RegExp _vowelMarks = RegExp('[${String.fromCharCode(0x591)}-${String.fromCharCode(0x5C7)}]');

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
/// anything else counts as the whole box.
Rect inkBoxOf(String svg) {
  const Rect whole = Rect.fromLTWH(0, 0, 1, 1);
  final RegExpMatch? vb = RegExp(r'viewBox="\s*([-\d.]+)[\s,]+([-\d.]+)[\s,]+([\d.]+)[\s,]+([\d.]+)')
      .firstMatch(svg);
  if (vb == null) return whole;
  final double vx = double.parse(vb[1]!);
  final double vy = double.parse(vb[2]!);
  final double vw = double.parse(vb[3]!);
  final double vh = double.parse(vb[4]!);
  final RegExpMatch? grp = RegExp(
    r'translate\(\s*([-\d.]+)[\s,]+([-\d.]+)\s*\)\s*scale\(\s*([\d.]+)\s*\)\s*translate\(',
  ).firstMatch(svg);
  final Offset pivot = grp == null ? Offset.zero : Offset(double.parse(grp[1]!), double.parse(grp[2]!));
  final double scale = grp == null ? 1 : double.parse(grp[3]!);
  double minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
  void add(double x, double y) {
    final Offset p = pivot + (Offset(x, y) - pivot) * scale;
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx);
    maxY = math.max(maxY, p.dy);
  }

  for (final RegExpMatch m in RegExp(
    r'<(rect|circle|ellipse|line|polygon|polyline|path)\b([^>]*)>',
  ).allMatches(svg)) {
    final String at = m[2]!;
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
    switch (m[1]) {
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
        final List<double> n = <double>[
          for (final RegExpMatch d in RegExp(
            r'-?[\d.]+',
          ).allMatches(RegExp(r'points="([^"]*)"').firstMatch(at)?[1] ?? ''))
            double.parse(d[0]!),
        ];
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
  if (!minX.isFinite) return whole;
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
  final double vx = double.parse(vb[1]!);
  final double vy = double.parse(vb[2]!);
  final double vw = double.parse(vb[3]!);
  final double vh = double.parse(vb[4]!);
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

class _Plans {
  _Plans(this.a, this.g) : k = hintScale(g.size);

  final TapAnswerActivity a;
  final TapGeometry g;
  final double k;

  // ---- small helpers ----

  static Duration _ms(int ms) => Duration(milliseconds: ms);

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

  /// The hand goes along the options (tiles) one after the other and ends on the right one: the demonstration of a question
  /// that has nothing else to do.
  HintPlan _walkOptions({List<HintMark> base = const <HintMark>[], int? to, double reserve = 0}) {
    final int last = to ?? _n - 1;
    return _demo(<HintFrame>[
      for (int i = 0; i <= last; i++)
        HintFrame(
          <HintMark>[...base, HandMark(g.optionTip(i), press: true)],
          hold: _ms(i == last && last == _ci ? 1300 : 850),
          reserve: reserve,
        ),
      if (last != _ci) _toAnswer(base, reserve: reserve),
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
    return _sample(level, (Rect box) => SwatchMark(box, c));
  }

  // ---- TA-7 shapes ----

  HintPlan shapes(int level) {
    if (level == 1) return look();
    switch (a.skillId) {
      case 'SHP-A-07':
        return _rolls(level);
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

  /// SHP-A-07: the ball rolls away and the box stays where it is (the question's own two things, no new ones).
  HintPlan _rolls(int level) {
    final ChoiceOption? ball = _first((String s) => s.contains('sphere') || s.contains('ball'));
    final ChoiceOption? box = _first((String s) => s.contains('box'));
    final String? ballSvg = _svg(ball?.sprite);
    final String? boxSvg = _svg(box?.sprite);
    if (ballSvg == null || boxSvg == null) return generic(level);
    final double side = 46 * k;
    final Rect ballAt = Rect.fromCenter(center: Offset(g.w * 0.22, g.h / 2), width: side, height: side);
    final Rect ballFar = Rect.fromCenter(center: Offset(g.w * 0.52, g.h / 2), width: side, height: side);
    final Rect boxAt = Rect.fromCenter(center: Offset(g.w * 0.8, g.h / 2), width: side, height: side);
    List<HintMark> scene(Rect b, {double turns = 0, bool trail = false}) => <HintMark>[
      CopyMark(boxAt, boxSvg),
      CopyMark(b, ballSvg, turns: turns),
      if (trail)
        LineMark(
          Offset(ballAt.center.dx, ballAt.bottom + 6 * k),
          Offset(ballFar.center.dx, ballFar.bottom + 6 * k),
        ),
    ];
    if (level == 2) {
      final List<HintMark> end = scene(ballFar, turns: 0.5, trail: true);
      return HintPlan(<HintFrame>[
        HintFrame(scene(ballAt), hold: _ms(900)),
        HintFrame(end, hold: _ms(2000)),
      ], rest: end);
    }
    return _walkOptions();
  }

  ChoiceOption? _first(bool Function(String sprite) test) {
    for (final ChoiceOption o in a.options) {
      if (o.sprite != null && test(o.sprite!)) return o;
    }
    return null;
  }

  /// SHP-A-08: the position of the question's word acted out with a box and a ball, in a sky card.
  HintPlan _position(int level) {
    final String where = (_right.sprite ?? '').replaceFirst('asset:pos_', '');
    final String? boxSvg = _svg('asset:solid_box');
    final String? ballSvg = _svg('asset:ball_red') ?? _svg('asset:solid_sphere');
    if (boxSvg == null ||
        ballSvg == null ||
        !<String>{'above', 'on', 'next', 'under', 'in'}.contains(where)) {
      return generic(level);
    }
    if (level == 3) return _walkOptions();
    final Rect card = g.centre(150 * k, 112 * k);
    final double b = 44 * k;
    final double d = 24 * k;
    final Offset c = card.center;
    final (Rect, Rect) place = switch (where) {
      'above' => (
        Rect.fromCenter(center: c + Offset(0, 24 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, -40 * k), width: d, height: d),
      ),
      'on' => (
        Rect.fromCenter(center: c + Offset(0, 18 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, -16 * k), width: d, height: d),
      ),
      'next' => (
        Rect.fromCenter(center: c + Offset(-26 * k, 10 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(30 * k, 22 * k), width: d, height: d),
      ),
      'under' => (
        Rect.fromCenter(center: c + Offset(0, -22 * k), width: b, height: b),
        Rect.fromCenter(center: c + Offset(0, 36 * k), width: d, height: d),
      ),
      _ => (
        Rect.fromCenter(center: c + Offset(0, 8 * k), width: b * 1.3, height: b * 1.3),
        Rect.fromCenter(center: c + Offset(0, 14 * k), width: d * 0.8, height: d * 0.8),
      ),
    };
    final List<HintMark> scene = <HintMark>[
      CardMark(card, const SizedBox.shrink()),
      CopyMark(place.$1, boxSvg),
      CopyMark(place.$2, ballSvg),
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
      copies = <HintMark>[
        for (final Rect r in top) CopyMark(r, sets[0].$1),
        for (final Rect r in bottom) CopyMark(r, sets[1].$1),
        LineMark(Offset(24 * k, 6 * k), Offset(24 * k, g.h - 6 * k)),
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
      return HintPlan(<HintFrame>[HintFrame(copies, hold: _ms(2600))], rest: copies);
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

  HintPlan sequence(int level) {
    if (a.skillId == 'NUM-A-13') return _ordinal(level);
    final int? c = _right.numeral;
    final String q = _plain(a.promptLine.caption);
    final bool before = q.contains(_before);
    final bool after = q.contains(_after);
    if (c == null || (!before && !after)) return generic(level);
    final int given = before ? c + 1 : c - 1;
    final int m = given <= 5 && c <= 5 && a.options.every((ChoiceOption o) => (o.numeral ?? 0) <= 5) ? 5 : 10;
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2 + 6 * k),
      width: math.min(g.w - 20, m * 30 * k),
      height: 36 * k,
    );
    Offset squareTop(int j) => Offset(path.left + (j - 0.5) * path.width / m, path.top + 2 * k);
    if (level == 1) {
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
        PathMark(rect: path, count: m, gap: gap, ring: ring, marker: marker);
    if (level == 2) {
      final List<HintMark> shown = <HintMark>[strip(gap: c, ring: given)];
      return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    }
    return _demo(<HintFrame>[
      for (int j = 1; j <= c; j++)
        HintFrame(<HintMark>[strip(gap: c, marker: j), HandMark(squareTop(j), press: true)], hold: _ms(620)),
      _toAnswer(<HintMark>[strip(marker: c)]),
    ]);
  }

  /// NUM-A-13: first, second, third, last. The tiles are the line, and the row of tiles starts at the right, so the numbered
  /// strip starts at the right too (the one place a strip of the stage is turned, to run the way the tiles run).
  HintPlan _ordinal(int level) {
    if (level == 1) return tilesInTurn();
    final Rect path = Rect.fromCenter(
      center: Offset(g.w / 2, g.h / 2),
      width: math.min(g.w - 20, _n * 44 * k),
      height: 40 * k,
    );
    if (level == 2) {
      final List<HintMark> shown = <HintMark>[PathMark(rect: path, count: _n, ring: _ci + 1, reverse: true)];
      return HintPlan(<HintFrame>[HintFrame(shown, hold: _ms(2800))], rest: shown);
    }
    Offset squareTop(int j) => Offset(path.right - (j - 0.5) * path.width / _n, path.top + 2 * k);
    return _demo(<HintFrame>[
      for (int j = 1; j <= _ci + 1; j++)
        HintFrame(<HintMark>[
          PathMark(rect: path, count: _n, marker: j, reverse: true),
          HandMark(squareTop(j), press: true),
        ], hold: _ms(800)),
      _toAnswer(<HintMark>[PathMark(rect: path, count: _n, ring: _ci + 1, reverse: true)]),
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
        // A row that grows (seriation): one floor under every cell, and the neighbours are linked.
        final List<HintMark> floor = <HintMark>[
          LineMark(Offset(cells.first.left, y), Offset(cells.last.right, y)),
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

  /// The hand reads the row from the left, and where there is a gap the right picture appears in it last.
  HintPlan _rowDemo(List<Rect> cells, int gap, {List<HintMark> base = const <HintMark>[]}) {
    final String? answerSvg = gap >= 0 ? _svg(_spriteOf(_right)) : null;
    final List<HintMark> filled = <HintMark>[
      ...base,
      if (answerSvg != null) CopyMark(cells[gap].deflate(3 * k), answerSvg),
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
    Widget hands(int raised) => raised <= 5
        ? HintHand(fingers: math.max(0, raised), side: HandSide.left, height: 84)
        : CountingHands(raised: raised);
    if (adds) {
      // Count on: the hand shows the first group, and the second group is counted one by one on top of it.
      final int more = second.length;
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
              CardMark(_card, hands(start + j)),
              ...done(j),
              BadgeMark(second[j - 1].topRight, start + j),
              HandMark(second[j - 1].center, press: true),
            ],
            hold: _ms(900),
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
    final List<(String, double, Rect)> things = <(String, double, Rect)>[
      for (final ChoiceOption o in a.options)
        if (_svg(_spriteOf(o)) != null)
          (_svg(_spriteOf(o))!, o.set?.scale ?? 1, _withStroke(inkBoxOf(_svg(_spriteOf(o))!))),
    ];
    if (things.length != 2) return generic(level);
    // Both things are drawn at one scale (the scale of a set kept), each in its own half of the stage, its drawn end on the
    // start line: what a child compares is the ink, not the picture's box (a short stick is drawn in the middle of its box).
    final double cube = 14 * k;
    final double startX = 30 * k;
    final double left = startX + 4 * k;
    final double band = g.h / 2;
    final double roomH = band - cube - 10 * k;
    final double roomW = g.w - left - 24 * k;
    double widest = 0;
    double tallest = 0;
    for (final (String _, double s, Rect ink) in things) {
      widest = math.max(widest, ink.width * s);
      tallest = math.max(tallest, ink.height * s);
    }
    double side = math.min(130 * k, math.min(roomW / widest, roomH / tallest));
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
            BlockMark(Rect.fromLTWH(left + c * cube, r.bottom + 3 * k, cube - 1.5, cube - 1.5)),
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
